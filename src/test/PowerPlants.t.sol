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

contract PowerPlantsTest is DSTest {
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
        iron.mint(homeworld, 10**27);
    }

    function testCreateUpgradePowerPlants(
        uint256 delay,
        uint256 rewardBase,
        uint256 rewardRate,
        uint256 costRate
    ) public {
        cheats.assume(delay < 10**18);
        cheats.assume(rewardBase > 0 && rewardBase < 2**223);
        cheats.assume(rewardRate > 0 && rewardRate < 2**223);
        cheats.assume(costRate > 0 && costRate < rewardBase);

        IResource[] memory powerPlantsCostsResources = new IResource[](1);
        powerPlantsCostsResources[0] = iron;
        uint256[] memory powerPlantsCostsBase = new uint256[](1);
        powerPlantsCostsBase[0] = 0;
        uint256[] memory powerPlantsCostsRates = new uint256[](1);
        powerPlantsCostsRates[0] = costRate;
        PowerPlants powerPlants = new PowerPlants(
            sanctis,
            energy,
            rewardBase,
            rewardRate,
            delay,
            powerPlantsCostsResources,
            powerPlantsCostsBase,
            powerPlantsCostsRates
        );
        sanctis.setAllowed(address(powerPlants), true);

        powerPlants.create(homeworld);

        uint256 blocksToWait = costRate / (rewardRate + rewardRate) + 1;
        blocksToWait = blocksToWait > delay ? blocksToWait : delay;
        cheats.roll(block.number + blocksToWait);

        uint256 reserveBefore = energy.reserve(homeworld);
        powerPlants.upgrade(homeworld);
        assertEq(
            energy.reserve(homeworld),
            reserveBefore + rewardBase + 2 * rewardRate
        );
    }
}