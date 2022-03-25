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
import "../races/Humans.sol";

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

    Sanctis sanctis;
    Commanders commanders;
    Humans humans;

    function setUp() public {
        sanctis = new Sanctis();
        commanders = new Commanders(sanctis);
        humans = new Humans(sanctis);

        sanctis.insertAndAllowExtension(commanders);
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

    function testFailCreateTooLong() public {
        commanders.create("TesteTesteTesteTesteTestee", humans);
    }
}
