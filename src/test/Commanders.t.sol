// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "ds-test/test.sol";

import "../Sanctis.sol";
import "../extensions/ISpaceCredits.sol";
import "../extensions/ICommanders.sol";
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

    function testCreateCommander() public {
        string[5] memory names = ["a", "b", "zzc", "dqsdfqsdfqs", "chfizqgk"];
        for (uint256 i = 0; i < names.length; i++) {
            commanders.create(names[i], humans);
            Commanders.Commander memory c = commanders.commander(
                commanders.tokenOfOwnerByIndex(address(this), i)
            );
            assertEq(c.name, names[i]);
            assertEq(address(c.race), address(humans));
        }
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
