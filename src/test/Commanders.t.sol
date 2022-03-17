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

contract CommandersTest is DSTest {
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
    Extractors extractors;
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

        humans = new Humans(sanctis);

        sanctis.setAllowed(address(humans), true);
    }

    function testCreate() public {
        commanders.create("Tester", humans);
        commanders.create("Tester and tests", humans);
        commanders.create("Testerrrrr", humans);
        commanders.create("Tester420", humans);
        commanders.create("Tester 420", humans);
    }

    function testFailCreateBadCharacter1() public {
        commanders.create("Tester_ujuj", humans);
    }
    
    function testFailCreateBadCharacter2() public {
        commanders.create("Tester+ujuj", humans);
    }
}
