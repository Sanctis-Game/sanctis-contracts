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
import "../infrastructures/ResourceProducer.sol";

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

contract ResourceProducerTest is DSTest {
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
        sanctis.setAllowed(address(silicon), true);
        sanctis.setAllowed(address(energy), true);

        commanders.create("Tester", humans);
        commanderId = 0;
        planets.colonize(commanderId, homeworld);
    }

    function testCreateUpgradeHarvest(
        uint256 delay,
        uint256 rewardBase,
        uint256 rewardRate,
        uint256 costRate
    ) public {
        cheats.assume(delay < 10**9);
        cheats.assume(rewardBase > 0 && rewardBase < 10**40);
        cheats.assume(rewardRate > 0 && rewardRate < 10**40);
        cheats.assume(costRate > 0 && costRate < rewardBase);

        IResource[] memory ironMinesRewardsResources = new IResource[](1);
        ironMinesRewardsResources[0] = iron;
        uint256[] memory ironMinesRewardsBase = new uint256[](1);
        ironMinesRewardsBase[0] = rewardBase;
        uint256[] memory ironMinesRewardsRates = new uint256[](1);
        ironMinesRewardsRates[0] = rewardRate;
        IResource[] memory ironMinesCostsResources = new IResource[](1);
        ironMinesCostsResources[0] = iron;
        uint256[] memory ironMinesCostsBase = new uint256[](1);
        ironMinesCostsBase[0] = 0;
        uint256[] memory ironMinesCostsRates = new uint256[](1);
        ironMinesCostsRates[0] = costRate;
        ResourceProducer ironMines = new ResourceProducer(
            sanctis,
            delay,
            ironMinesRewardsResources,
            ironMinesRewardsBase,
            ironMinesRewardsRates,
            ironMinesCostsResources,
            ironMinesCostsBase,
            ironMinesCostsRates
        );
        sanctis.setAllowed(address(ironMines), true);

        ironMines.create(homeworld);

        uint256 blocksToWait = costRate / (rewardRate + rewardRate) + 1;
        blocksToWait = blocksToWait > delay ? blocksToWait : delay;
        cheats.roll(block.number + blocksToWait);

        ironMines.upgrade(homeworld);

        cheats.roll(block.number + 1);

        uint256 reserveBefore = iron.reserve(homeworld);
        ironMines.harvest(homeworld);
        assertEq(
            iron.reserve(homeworld),
            reserveBefore + rewardBase + 2 * rewardRate
        );
    }

    function testFailCreate(
        uint256 delay,
        uint256 rewardBase,
        uint256 rewardRate,
        uint256 costRate
    ) public {
        cheats.assume(delay < 10**18);
        cheats.assume(rewardBase > 0 && rewardBase < 2**224);
        cheats.assume(rewardRate > 0 && rewardRate < 2**224);
        cheats.assume(costRate > 0 && costRate < rewardBase);

        IResource[] memory ironMinesRewardsResources = new IResource[](1);
        ironMinesRewardsResources[0] = iron;
        uint256[] memory ironMinesRewardsBase = new uint256[](1);
        ironMinesRewardsBase[0] = rewardBase;
        uint256[] memory ironMinesRewardsRates = new uint256[](1);
        ironMinesRewardsRates[0] = rewardRate;
        IResource[] memory ironMinesCostsResources = new IResource[](1);
        ironMinesCostsResources[0] = iron;
        uint256[] memory ironMinesCostsBase = new uint256[](1);
        ironMinesCostsBase[0] = 0;
        uint256[] memory ironMinesCostsRates = new uint256[](1);
        ironMinesCostsRates[0] = costRate;
        ResourceProducer ironMines = new ResourceProducer(
            sanctis,
            delay,
            ironMinesRewardsResources,
            ironMinesRewardsBase,
            ironMinesRewardsRates,
            ironMinesCostsResources,
            ironMinesCostsBase,
            ironMinesCostsRates
        );
        sanctis.setAllowed(address(ironMines), true);

        address other = address(65498796);
        cheats.prank(other, other);
        ironMines.create(homeworld);
    }

    function testFailUpgradeDelay(
        uint256 delay,
        uint256 rewardBase,
        uint256 rewardRate,
        uint256 costRate
    ) public {
        cheats.assume(delay > 0 && delay < 10**18);
        cheats.assume(rewardBase > 0 && rewardBase < 2**224);
        cheats.assume(rewardRate > 0 && rewardRate < 2**224);
        cheats.assume(costRate > 0 && costRate < rewardBase);

        IResource[] memory ironMinesRewardsResources = new IResource[](1);
        ironMinesRewardsResources[0] = iron;
        uint256[] memory ironMinesRewardsBase = new uint256[](1);
        ironMinesRewardsBase[0] = rewardBase;
        uint256[] memory ironMinesRewardsRates = new uint256[](1);
        ironMinesRewardsRates[0] = rewardRate;
        IResource[] memory ironMinesCostsResources = new IResource[](1);
        ironMinesCostsResources[0] = iron;
        uint256[] memory ironMinesCostsBase = new uint256[](1);
        ironMinesCostsBase[0] = 0;
        uint256[] memory ironMinesCostsRates = new uint256[](1);
        ironMinesCostsRates[0] = costRate;
        ResourceProducer ironMines = new ResourceProducer(
            sanctis,
            delay,
            ironMinesRewardsResources,
            ironMinesRewardsBase,
            ironMinesRewardsRates,
            ironMinesCostsResources,
            ironMinesCostsBase,
            ironMinesCostsRates
        );
        sanctis.setAllowed(address(ironMines), true);

        ironMines.create(homeworld);

        ironMines.upgrade(homeworld);
    }

    function testFailUpgradeResources(uint256 costRate) public {
        uint256 delay = 0;
        uint256 rewardBase = 0;
        uint256 rewardRate = 0;
        cheats.assume(costRate > 0 && costRate < 2 * 224);

        IResource[] memory ironMinesRewardsResources = new IResource[](1);
        ironMinesRewardsResources[0] = iron;
        uint256[] memory ironMinesRewardsBase = new uint256[](1);
        ironMinesRewardsBase[0] = rewardBase;
        uint256[] memory ironMinesRewardsRates = new uint256[](1);
        ironMinesRewardsRates[0] = rewardRate;
        IResource[] memory ironMinesCostsResources = new IResource[](1);
        ironMinesCostsResources[0] = iron;
        uint256[] memory ironMinesCostsBase = new uint256[](1);
        ironMinesCostsBase[0] = 0;
        uint256[] memory ironMinesCostsRates = new uint256[](1);
        ironMinesCostsRates[0] = costRate;
        ResourceProducer ironMines = new ResourceProducer(
            sanctis,
            delay,
            ironMinesRewardsResources,
            ironMinesRewardsBase,
            ironMinesRewardsRates,
            ironMinesCostsResources,
            ironMinesCostsBase,
            ironMinesCostsRates
        );
        sanctis.setAllowed(address(ironMines), true);

        ironMines.create(homeworld);

        uint256 blocksToWait = costRate / (rewardRate + rewardRate) + 1;
        blocksToWait = blocksToWait > delay ? blocksToWait : delay;
        cheats.roll(block.number + blocksToWait);

        ironMines.upgrade(homeworld);
    }
}
