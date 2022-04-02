// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "ds-test/test.sol";
import "openzeppelin-contracts/contracts/governance/extensions/GovernorTimelockControl.sol";
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

import "../Sanctis.sol";
import "../extensions/SpaceCredits.sol";
import "../extensions/Commanders.sol";
import "../extensions/Planets.sol";
import "../extensions/Fleets.sol";
import "../races/Humans.sol";
import "../resources/Resource.sol";
import "../infrastructures/Spatioports.sol";
import "../ships/Ship.sol";
import "../utils/ResourceWrapper.sol";

interface CheatCodes {
    // Sets the *next* call's msg.sender to be the input address, and the tx.origin to be the second input
    function prank(address, address) external;

    // Set block.number
    function roll(uint256) external;

    // Set block.timestamp
    function warp(uint256) external;
}

contract ResourceWrapperTest is DSTest {
    CheatCodes cheats = CheatCodes(HEVM_ADDRESS);

    uint256 constant COLONIZATION_COST = 10**18;
    uint256 constant CITIZEN_CAPACITY = 1000;
    uint256 constant EXTRACTORS_BASE_REWARDS = 1000;
    uint256 constant EXTRACTORS_REWARDS_RATE = 1000;
    uint256 constant EXTRACTORS_DELAY = 1000;
    uint256 constant TRANSPORTERS_CAPACITY = 10**18;
    uint256 constant TRANSPORTERS_SPEED = 1000;
    uint256 constant PLUNDER_PERIOD = 10;
    uint256 constant PLUNDER_RATE = 1000;

    Sanctis sanctis;
    SpaceCredits credits;
    Parliament parliament;
    Commanders commanders;
    Planets planets;
    Fleets fleets;
    ResourceWrapper wrapper;

    Humans humans;
    Resource iron;
    Spatioports spatioports;
    Ship transporters;

    function setUp() public {
        sanctis = new Sanctis();

        credits = new SpaceCredits(sanctis);
        commanders = new Commanders(sanctis);
        planets = new Planets(sanctis, COLONIZATION_COST);
        fleets = new Fleets(sanctis, PLUNDER_PERIOD, PLUNDER_RATE);
        wrapper = new ResourceWrapper(sanctis);

        sanctis.setParliamentExecutor(address(this));

        sanctis.insertAndAllowExtension(credits);
        sanctis.insertAndAllowExtension(commanders);
        sanctis.insertAndAllowExtension(planets);
        sanctis.insertAndAllowExtension(fleets);

        credits.mint(address(this), 10**27);

        humans = new Humans(sanctis);
        iron = new Resource(sanctis, "Iron", "IRON");

        spatioports = new Spatioports(
            sanctis,
            EXTRACTORS_DELAY,
            new IResource[](0),
            new uint256[](0),
            new uint256[](0)
        );

        uint256 transportersDefensivePower = 100;
        transporters = new Ship(
            sanctis,
            TRANSPORTERS_SPEED,
            0,
            transportersDefensivePower,
            TRANSPORTERS_CAPACITY,
            new IResource[](0),
            new uint256[](0)
        );

        sanctis.setAllowed(address(humans), true);
        sanctis.setAllowed(address(iron), true);
        sanctis.setAllowed(address(spatioports), true);
        sanctis.setAllowed(address(transporters), true);
        sanctis.setAllowed(address(wrapper), true);
        sanctis.setAllowed(address(this), true);
    }

    function testMintFromFleet() public {
        uint256 homeworld = 1020;
        commanders.create("Tester", humans);
        credits.approve(address(planets), COLONIZATION_COST * 2);
        planets.colonize(0, homeworld);
        iron.mint(homeworld, 10**27);
        spatioports.create(homeworld);

        uint256 fleetId = 20898;
        uint256 transportersCount = 100;
        uint256 wrappedQuantity = 10**18;
        fleets.createFleet(fleetId, 0, homeworld);
        spatioports.build(homeworld, transporters, transportersCount);
        fleets.addToFleet(fleetId, transporters, transportersCount);
        fleets.load(fleetId, iron, wrappedQuantity);

        commanders.setApprovalForAll(address(wrapper), true);
        wrapper.mintFromFleet(fleetId, iron, wrappedQuantity);
        assertEq(
            IERC20(wrapper.getToken(iron, homeworld)).balanceOf(address(this)),
            wrappedQuantity
        );
    }

    function testBurnToFleet() public {
        uint256 homeworld = 1020;
        commanders.create("Tester", humans);
        credits.approve(address(planets), COLONIZATION_COST * 2);
        planets.colonize(0, homeworld);
        iron.mint(homeworld, 10**27);
        spatioports.create(homeworld);

        uint256 fleetId = 20898;
        uint256 transportersCount = 100;
        uint256 wrappedQuantity = 10**18;
        fleets.createFleet(fleetId, 0, homeworld);
        spatioports.build(homeworld, transporters, transportersCount);
        fleets.addToFleet(fleetId, transporters, transportersCount);
        fleets.load(fleetId, iron, wrappedQuantity);
        commanders.setApprovalForAll(address(wrapper), true);
        wrapper.mintFromFleet(fleetId, iron, wrappedQuantity);

        wrapper.burnToFleet(fleetId, iron, wrappedQuantity);
        assertEq(
            IERC20(wrapper.getToken(iron, homeworld)).balanceOf(address(this)),
            0
        );
        assertEq(iron.reserve(homeworld), 10**27 - wrappedQuantity);
    }
}
