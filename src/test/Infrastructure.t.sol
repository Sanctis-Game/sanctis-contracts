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

contract InfrastructuresTest is DSTest {
    CheatCodes cheats = CheatCodes(HEVM_ADDRESS);

    Sanctis sanctis;
    SpaceCredits credits;
    Commanders commanders;
    Planets planets;
    Humans humans;
    Resource iron;
    Resource silicon;
    Energy energy;

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

        sanctis.setParliamentExecutor(address(this));
        sanctis.insertAndAllowExtension(credits);
        sanctis.insertAndAllowExtension(commanders);
        sanctis.insertAndAllowExtension(planets);
        sanctis.setAllowed(address(humans), true);
        sanctis.setAllowed(address(iron), true);
        sanctis.setAllowed(address(energy), true);
        sanctis.setAllowed(address(this), true);

        commanders.create("Tester", humans);
        commanderId = 0;
        planets.colonize(commanderId, homeworld);
    }

    function testCreateUpgradeInfrastructure(
        uint256 startingLevel,
        uint256 delay,
        uint256 costBase,
        uint256 costRate
    ) public {
        cheats.assume(startingLevel < 10**4);
        cheats.assume(delay < 10**9);
        cheats.assume(costBase > 0 && costBase < 10**40);
        cheats.assume(costRate > 0 && costRate < 10**40);

        IResource[] memory infrastructureCostsResources = new IResource[](1);
        infrastructureCostsResources[0] = iron;
        uint256[] memory infrastructureCostsBase = new uint256[](1);
        infrastructureCostsBase[0] = costBase;
        uint256[] memory infrastructureCostsRates = new uint256[](1);
        infrastructureCostsRates[0] = costRate;
        Infrastructure infrastructure = new Infrastructure(
            sanctis,
            delay,
            infrastructureCostsResources,
            infrastructureCostsBase,
            infrastructureCostsRates
        );

        sanctis.setAllowed(address(infrastructure), true);
        iron.mint(homeworld, 2**223);

        uint256 reserveBefore = iron.reserve(homeworld);
        infrastructure.create(homeworld);
        assertEq(iron.reserve(homeworld), reserveBefore - costBase);

        for (uint256 i; i < startingLevel; i++) {
            cheats.roll(block.number + delay * (i + 1));
            reserveBefore = iron.reserve(homeworld);
            (, uint256[] memory pastCosts) = infrastructure.costsNextLevel(
                homeworld
            );
            infrastructure.upgrade(homeworld);
            assertEq(iron.reserve(homeworld), reserveBefore - pastCosts[0]);
        }
    }
}