// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "ds-test/test.sol";
import "openzeppelin-contracts/contracts/governance/extensions/GovernorTimelockControl.sol";
import "openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Votes.sol";

import "../Sanctis.sol";
import "../interfaces/ISpaceCredits.sol";
import "../extensions/SpaceCredits.sol";
import "../extensions/Commanders.sol";
import "../extensions/Planets.sol";
import "../extensions/Fleets.sol";
import "../races/Humans.sol";
import "../resources/Iron.sol";
import "../infrastructures/Extractors.sol";
import "../infrastructures/Spatioports.sol";
import "../ships/Transporters.sol";

interface CheatCodes {
    // Sets the *next* call's msg.sender to be the input address, and the tx.origin to be the second input
    function prank(address, address) external;

    // Set block.number
    function roll(uint256) external;

    // Set block.timestamp
    function warp(uint256) external;
}

contract SanctisTest is DSTest {
    CheatCodes cheats = CheatCodes(HEVM_ADDRESS);

    uint256 constant COLONIZATION_COST = 10**18;
    uint256 constant CITIZEN_CAPACITY = 1000;
    uint256 constant EXTRACTORS_BASE_REWARDS = 1000;
    uint256 constant EXTRACTORS_REWARDS_RATE = 1000;
    uint256 constant EXTRACTORS_DELAY = 1000;
    uint256 constant TRANSPORTERS_CAPACITY = 1000;
    uint256 constant TRANSPORTERS_SPEED = 1000;

    Sanctis sanctis;
    SpaceCredits credits;
    Parliament parliament;
    Commanders commanders;
    Planets planets;
    Fleets fleets;

    Humans humans;
    Iron iron;
    Extractors ironExtractors;
    Spatioports spatioports;
    Transporters transporters;

    function setUp() public {
        sanctis = new Sanctis();

        credits = new SpaceCredits(sanctis);
        commanders = new Commanders(sanctis);
        planets = new Planets(
            sanctis,
            COLONIZATION_COST
        );
        fleets = new Fleets(sanctis);

        sanctis.setParliamentExecutor(address(this));

        sanctis.insertAndAllowExtension(credits);
        sanctis.insertAndAllowExtension(commanders);
        sanctis.insertAndAllowExtension(planets);
        sanctis.insertAndAllowExtension(fleets);

        credits.mint(address(this), 10**27);

        humans = new Humans(sanctis);
        iron = new Iron(sanctis);

        Cost[] memory extractorsCosts = new Cost[](1);
        extractorsCosts[0].resource = iron;
        extractorsCosts[0].quantity = 0;
        Cost[] memory extractorsRates = new Cost[](1);
        extractorsRates[0].resource = iron;
        extractorsRates[0].quantity = 100;
        ironExtractors = new Extractors(
            sanctis,
            iron,
            EXTRACTORS_BASE_REWARDS,
            EXTRACTORS_REWARDS_RATE,
            EXTRACTORS_DELAY,
            extractorsCosts,
            extractorsRates
        );

        Cost[] memory spatioportsCosts = new Cost[](1);
        spatioportsCosts[0].resource = iron;
        spatioportsCosts[0].quantity = 100;
        Cost[] memory spatioportsRates = new Cost[](1);
        spatioportsRates[0].resource = iron;
        spatioportsRates[0].quantity = 100;
        spatioports = new Spatioports(
            sanctis,
            EXTRACTORS_DELAY,
            spatioportsCosts,
            spatioportsRates
        );

        Cost[] memory transportersCosts = new Cost[](1);
        transportersCosts[0].resource = iron;
        transportersCosts[0].quantity = 100;
        transporters = new Transporters(
            sanctis,
            TRANSPORTERS_CAPACITY,
            TRANSPORTERS_SPEED,
            transportersCosts
        );

        sanctis.setAllowed(address(humans), true);
        sanctis.setAllowed(address(iron), true);
        sanctis.setAllowed(address(ironExtractors), true);
        sanctis.setAllowed(address(spatioports), true);
        sanctis.setAllowed(address(transporters), true);
    }

    function testCreateCitizen() public {
        uint256 homeworld = 1020;
        commanders.create("Tester", humans);
        planets.create(homeworld);
        credits.approve(address(planets), COLONIZATION_COST);
        planets.colonize(commanders.created(), homeworld);

        ironExtractors.create(homeworld);
        assertEq(iron.reserve(homeworld), 0);

        // Testing harvesting
        uint256 elapsedBlocks = 1;
        cheats.roll(block.number + elapsedBlocks);
        ironExtractors.harvest(homeworld);
        assertEq(
            iron.reserve(homeworld),
            (EXTRACTORS_BASE_REWARDS + EXTRACTORS_REWARDS_RATE) * elapsedBlocks
        );

        // Upgrades increase production but consumes resources
        cheats.roll(block.number + EXTRACTORS_DELAY);
        ironExtractors.upgrade(homeworld);
        cheats.roll(block.number + EXTRACTORS_DELAY);

        uint256 ironReserveBefore = iron.reserve(homeworld);
        cheats.roll(block.number + elapsedBlocks);
        ironExtractors.harvest(homeworld);
        uint256 ironReserve = iron.reserve(homeworld);
        assertEq(
            ironReserve,
            (EXTRACTORS_BASE_REWARDS + 2 * EXTRACTORS_REWARDS_RATE) *
                elapsedBlocks +
                ironReserveBefore
        );

        spatioports.create(homeworld);
        assertEq(iron.reserve(homeworld), ironReserve - 100);

        uint256 transportersCount = 100;
        ironReserve = iron.reserve(homeworld);
        spatioports.build(homeworld, transporters, transportersCount);
        assertEq(iron.reserve(homeworld), ironReserve - 100 * transportersCount);
        assertEq(transporters.reserve(homeworld), transportersCount);

        uint256 fleetId = 42;
        uint256 transportedQuantity = 1000;
        fleets.createFleet(fleetId, 1, homeworld);
        commanders.setApprovalForAll(address(transporters), true);
        commanders.setApprovalForAll(address(fleets), true);
        transporters.addToFleet(fleetId, transportersCount, iron, transportedQuantity);
    }
}
