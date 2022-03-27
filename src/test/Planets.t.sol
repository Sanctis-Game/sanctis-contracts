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
import "../infrastructures/Spatioports.sol";

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

    function setUp() public {
        sanctis = new Sanctis();
        credits = new SpaceCredits(sanctis);
        commanders = new Commanders(sanctis);
        planets = new Planets(sanctis, 0);
        humans = new Humans(sanctis);

        sanctis.setParliamentExecutor(address(this));
        sanctis.insertAndAllowExtension(credits);
        sanctis.insertAndAllowExtension(commanders);
        sanctis.insertAndAllowExtension(planets);
        sanctis.setAllowed(address(humans), true);
    }

    function testCreatePlanet(uint256 homeworld) public {
        cheats.assume(
            homeworld != 0 && homeworld < type(uint240).max
        );

        commanders.create("T", humans);
        planets.create(homeworld);
    }

    function testColonizePlanet(uint256 cost, uint256 homeworld) public {
        cheats.assume(
            cost < 2**224 && homeworld != 0 && homeworld < type(uint240).max
        );

        planets = new Planets(sanctis, cost);
        sanctis.insertAndAllowExtension(planets);

        credits.mint(address(this), cost);
        commanders.create("T", humans);
        credits.approve(address(planets), cost);
        planets.colonize(commanders.created(), homeworld);
    }
}
