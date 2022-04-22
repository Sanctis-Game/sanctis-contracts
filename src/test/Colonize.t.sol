// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "ds-test/test.sol";

import "../Sanctis.sol";
import "../extensions/ISpaceCredits.sol";
import "../extensions/SpaceCredits.sol";
import "../extensions/Commanders.sol";
import "../extensions/Planets.sol";
import "../extensions/Fleets.sol";
import "../races/Humans.sol";
import "../infrastructures/Spatioports.sol";
import "../modules/Colonize.sol";

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

contract PlanetsTest is DSTest {
    CheatCodes cheats = CheatCodes(HEVM_ADDRESS);

    Sanctis sanctis;
    SpaceCredits credits;
    Commanders commanders;
    Planets planets;
    Humans humans;
    Colonize colonize;

    function setUp() public {
        sanctis = new Sanctis();
        credits = new SpaceCredits(sanctis);
        commanders = new Commanders(sanctis);
        planets = new Planets(sanctis);
        humans = new Humans(sanctis);
        colonize = new Colonize(sanctis, 0);

        sanctis.setParliamentExecutor(address(this));
        sanctis.insertAndAllowExtension(credits);
        sanctis.insertAndAllowExtension(commanders);
        sanctis.insertAndAllowExtension(planets);
        sanctis.setAllowed(address(humans), true);
        sanctis.setAllowed(address(colonize), true);
    }

    function testColonizePlanet(uint256 cost, uint256 homeworld) public {
        cheats.assume(
            cost < 2**224 && homeworld != 0 && homeworld < type(uint240).max
        );

        planets = new Planets(sanctis);
        sanctis.insertAndAllowExtension(planets);

        credits.mint(address(this), cost);
        commanders.create("T", humans);
        credits.approve(address(planets), cost);
        colonize.colonize(commanders.created(), homeworld);

        assertEq(planets.planet(homeworld).ruler, commanders.created());
    }
}
