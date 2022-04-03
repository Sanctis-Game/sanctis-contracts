// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "ds-test/test.sol";
import "openzeppelin-contracts/contracts/governance/extensions/GovernorTimelockControl.sol";
import "openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Votes.sol";

import "../Sanctis.sol";
import "../extensions/ISpaceCredits.sol";
import "../extensions/SpaceCredits.sol";
import "../extensions/Commanders.sol";
import "../extensions/Planets.sol";
import "../extensions/Fleets.sol";
import "../races/Humans.sol";
import "../resources/Resource.sol";
import "../resources/Energy.sol";
import "../infrastructures/PowerPlants.sol";
import "../infrastructures/Spatioports.sol";
import "../ships/Ship.sol";
import "../modules/Plundering.sol";

interface CheatCodes {
    // Sets the *next* call's msg.sender to be the input address, and the tx.origin to be the second input
    function prank(address, address) external;

    // Set block.number
    function roll(uint256) external;

    // Set block.timestamp
    function warp(uint256) external;

    // When fuzzing, generate new inputs if conditional not met
    function assume(bool) external;
}

contract PlunderingTest is DSTest {
    CheatCodes cheats = CheatCodes(HEVM_ADDRESS);

    Sanctis sanctis;
    SpaceCredits credits;
    Commanders commanders;
    Planets planets;
    Fleets fleets;
    Humans humans;
    Resource iron;
    Resource silicon;
    Energy energy;
    Spatioports spatioports;
    Ship ship;
    Plundering plundering;

    uint256 commanderId;
    uint256 homeworld = 456789;
    uint256 otherworld = 456786;
    uint256 fleetId = 456786;

    function setUp() public {
        sanctis = new Sanctis();
        credits = new SpaceCredits(sanctis);
        commanders = new Commanders(sanctis);
        planets = new Planets(sanctis, 0);
        fleets = new Fleets(sanctis);
        humans = new Humans(sanctis);
        iron = new Resource(sanctis, "Iron", "IRON");
        silicon = new Resource(sanctis, "Silicon", "SILI");
        energy = new Energy(sanctis);

        IResource[] memory infrastructureCostsResources = new IResource[](1);
        infrastructureCostsResources[0] = iron;
        uint256[] memory infrastructureCostsBase = new uint256[](1);
        infrastructureCostsBase[0] = 0;
        uint256[] memory infrastructureCostsRates = new uint256[](1);
        infrastructureCostsRates[0] = 0;
        spatioports = new Spatioports(
            sanctis,
            0,
            infrastructureCostsResources,
            infrastructureCostsBase,
            infrastructureCostsRates,
            9900
        );
        IResource[] memory shipCostsResources = new IResource[](1);
        shipCostsResources[0] = iron;
        uint256[] memory shipCostsBase = new uint256[](1);
        shipCostsBase[0] = 10;
        ship = new Ship(
            sanctis,
            100,
            100,
            100,
            10**40,
            shipCostsResources,
            shipCostsBase
        );

        sanctis.setParliamentExecutor(address(this));
        sanctis.insertAndAllowExtension(credits);
        sanctis.insertAndAllowExtension(commanders);
        sanctis.insertAndAllowExtension(planets);
        sanctis.insertAndAllowExtension(fleets);
        sanctis.setAllowed(address(humans), true);
        sanctis.setAllowed(address(iron), true);
        sanctis.setAllowed(address(energy), true);
        sanctis.setAllowed(address(spatioports), true);
        sanctis.setAllowed(address(ship), true);
        sanctis.setAllowed(address(this), true);

        iron.mint(homeworld, 2**223);

        commanders.create("Tester", humans);
        commanderId = 0;
        planets.colonize(commanderId, homeworld);
        planets.colonize(commanderId, otherworld);
        spatioports.create(homeworld);

        spatioports.build(homeworld, ship, 1);
        fleets.createFleet(fleetId, commanderId, homeworld);
        fleets.addToFleet(fleetId, ship, 1);
        fleets.putInOrbit(fleetId);
        fleets.moveFleet(fleetId, otherworld);
        cheats.roll(fleets.fleet(fleetId).arrivalBlock);
        fleets.settleFleet(fleetId);
    }

    function testPlunder(
        uint256 plunderPeriod,
        uint256 plunderRatio,
        uint256 planetReserve
    ) public {
        cheats.assume(plunderPeriod > 0 && plunderPeriod < 10**18);
        cheats.assume(plunderRatio <= 10000);
        cheats.assume(planetReserve < 10**40);

        iron.mint(otherworld, planetReserve);

        IResource[] memory infrastructureCostsResources = new IResource[](1);
        infrastructureCostsResources[0] = iron;
        uint256[] memory infrastructureCostsBase = new uint256[](1);
        infrastructureCostsBase[0] = 0;
        plundering = new Plundering(sanctis, plunderPeriod, plunderRatio);
        sanctis.setAllowed(address(plundering), true);

        cheats.roll(block.number + plunderPeriod);

        plundering.plunder(fleetId, iron);
        assertEq(
            fleets.resourceInFleet(iron, fleetId),
            (planetReserve * plunderRatio) / 10000
        );
    }
}
