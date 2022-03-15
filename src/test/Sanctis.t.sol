// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "ds-test/test.sol";
import "openzeppelin-contracts/contracts/governance/extensions/GovernorTimelockControl.sol";
import "openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Votes.sol";

import "../interfaces/ISpaceCredits.sol";
import "../Sanctis.sol";
import "../SpaceCredits.sol";
import "../Commanders.sol";
import "../GalacticStandards.sol";
import "../Planets.sol";
import "../Fleets.sol";
import "../RaceRegistry.sol";
import "../ResourceRegistry.sol";
import "../InfrastructureRegistry.sol";
import "../ShipRegistry.sol";

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
    GalacticStandards standards;
    Planets planets;
    Fleets fleets;

    RaceRegistry raceRegistry;
    ResourceRegistry resourceRegistry;
    InfrastructureRegistry infrastructureRegistry;
    ShipRegistry shipRegistry;

    Humans humans;
    Iron iron;
    Extractors extractors;
    Spatioports spatioports;
    Transporters transporters;

    function setUp() public {
        sanctis = new Sanctis();
        credits = new SpaceCredits();
        parliament = new Parliament(
            ERC20Votes(credits),
            TimelockController(payable(address(this)))
        );
        sanctis.setGovernance(
            address(parliament),
            address(this),
            ISpaceCredits(address(credits))
        );
        credits.transferOwnership(sanctis.parliamentExecutor());

        commanders = new Commanders(sanctis);
        standards = new GalacticStandards(address(sanctis));
        planets = new Planets(
            sanctis,
            ISpaceCredits(address(credits)),
            COLONIZATION_COST
        );
        fleets = new Fleets(sanctis);
        sanctis.setWorld(
            planets,
            commanders,
            fleets,
            standards,
            CITIZEN_CAPACITY
        );

        raceRegistry = new RaceRegistry();
        resourceRegistry = new ResourceRegistry();
        infrastructureRegistry = new InfrastructureRegistry();
        shipRegistry = new ShipRegistry();
        sanctis.setRegistries(
            raceRegistry,
            resourceRegistry,
            infrastructureRegistry,
            shipRegistry
        );

        humans = new Humans(sanctis);
        iron = new Iron(sanctis);

        Cost[] memory extractorsCosts = new Cost[](1);
        extractorsCosts[0].resourceId = 1;
        extractorsCosts[0].quantity = 0;
        Cost[] memory extractorsRates = new Cost[](1);
        extractorsRates[0].resourceId = 1;
        extractorsRates[0].quantity = 100;
        extractors = new Extractors(
            sanctis,
            iron.id(),
            EXTRACTORS_BASE_REWARDS,
            EXTRACTORS_REWARDS_RATE,
            EXTRACTORS_DELAY,
            extractorsCosts,
            extractorsRates
        );

        Cost[] memory spatioportsCosts = new Cost[](1);
        spatioportsCosts[0].resourceId = 1;
        spatioportsCosts[0].quantity = 100;
        Cost[] memory spatioportsRates = new Cost[](1);
        spatioportsRates[0].resourceId = 1;
        spatioportsRates[0].quantity = 100;
        spatioports = new Spatioports(
            sanctis,
            EXTRACTORS_DELAY,
            spatioportsCosts,
            spatioportsRates
        );

        Cost[] memory transportersCosts = new Cost[](1);
        transportersCosts[0].resourceId = 1;
        transportersCosts[0].quantity = 100;
        transporters = new Transporters(
            sanctis,
            TRANSPORTERS_CAPACITY,
            TRANSPORTERS_SPEED,
            transportersCosts
        );

        sanctis.add(IGalacticStandards.StandardType.Race, humans.id());
        sanctis.add(IGalacticStandards.StandardType.Resource, iron.id());
        sanctis.add(
            IGalacticStandards.StandardType.Infrastructure,
            extractors.id()
        );
        sanctis.add(
            IGalacticStandards.StandardType.Infrastructure,
            spatioports.id()
        );
        sanctis.add(IGalacticStandards.StandardType.Ship, transporters.id());
    }

    function testCreateCitizen() public {
        uint256 homeworld = 0;
        commanders.create("Tester", humans.id());
        sanctis.onboard(commanders.created());
        planets.create(homeworld);
        credits.approve(address(planets), COLONIZATION_COST);
        planets.colonize(commanders.created(), homeworld);

        extractors.create(homeworld);
        assertEq(iron.reserve(homeworld), 0);

        // Testing harvesting
        uint256 elapsedBlocks = 1;
        cheats.roll(block.number + elapsedBlocks);
        extractors.harvest(homeworld);
        assertEq(
            iron.reserve(homeworld),
            (EXTRACTORS_BASE_REWARDS + EXTRACTORS_REWARDS_RATE) * elapsedBlocks
        );

        // Upgrades increase production but consumes resources
        cheats.roll(block.number + EXTRACTORS_DELAY);
        extractors.upgrade(homeworld);
        cheats.roll(block.number + EXTRACTORS_DELAY);

        uint256 ironReserveBefore = iron.reserve(homeworld);
        cheats.roll(block.number + elapsedBlocks);
        extractors.harvest(homeworld);
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
    }
}
