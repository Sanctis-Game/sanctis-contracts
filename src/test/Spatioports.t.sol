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

contract SpatioportsTest is DSTest {
    CheatCodes cheats = CheatCodes(HEVM_ADDRESS);

    Sanctis sanctis;
    SpaceCredits credits;
    Commanders commanders;
    Planets planets;
    Humans humans;
    Resource iron;
    Resource silicon;
    Energy energy;
    Spatioports spatioports;
    Ship ship;

    uint256 commanderId;
    uint256 homeworld = 456789;

    function setUp() public {
        sanctis = new Sanctis();
        credits = new SpaceCredits(sanctis);
        commanders = new Commanders(sanctis);
        planets = new Planets(sanctis, 0);
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

        sanctis.setParliamentExecutor(address(this));
        sanctis.insertAndAllowExtension(credits);
        sanctis.insertAndAllowExtension(commanders);
        sanctis.insertAndAllowExtension(planets);
        sanctis.setAllowed(address(humans), true);
        sanctis.setAllowed(address(iron), true);
        sanctis.setAllowed(address(energy), true);
        sanctis.setAllowed(address(spatioports), true);
        sanctis.setAllowed(address(this), true);

        commanders.create("Tester", humans);
        commanderId = 1;
        planets.colonize(commanderId, homeworld);
        spatioports.create(homeworld);
    }

    function testBuildShips(uint256 shipCost, uint256 shipAmount) public {
        cheats.assume(shipCost > 0 && shipCost < 10**40);
        cheats.assume(shipAmount > 0 && shipAmount < 10**18);

        IResource[] memory shipCostsResources = new IResource[](1);
        shipCostsResources[0] = iron;
        uint256[] memory shipCostsBase = new uint256[](1);
        shipCostsBase[0] = shipCost;
        ship = new Ship(
            sanctis,
            100,
            100,
            100,
            0,
            shipCostsResources,
            shipCostsBase
        );

        sanctis.setAllowed(address(ship), true);
        iron.mint(homeworld, 2**223);

        uint256 reserveBefore = iron.reserve(homeworld);
        spatioports.build(homeworld, ship, shipAmount);
        assertEq(
            iron.reserve(homeworld),
            reserveBefore -
                (shipAmount *
                    shipCost *
                    (spatioports.discountFactor()**2 / 10000)) /
                10000
        );
    }
}
