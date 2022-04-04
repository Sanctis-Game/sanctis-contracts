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

    function startPrank(address, address) external;

    function stopPrank() external;

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

    address player = address(654873213897);
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

        iron.mint(homeworld, 10**27);

        cheats.startPrank(player, player);
        commanders.create("Tester", humans);
        commanderId = 0;
        planets.colonize(commanderId, homeworld);
        cheats.stopPrank();
    }

    function testCreatePowerPlants(uint256 rewardBase, uint256 rewardRate)
        public
    {
        cheats.assume(rewardBase > 0 && rewardBase < 10**40);
        cheats.assume(rewardRate > 0 && rewardRate < 10**40);

        IResource[] memory powerPlantsCostsResources = new IResource[](1);
        powerPlantsCostsResources[0] = iron;
        uint256[] memory powerPlantsCostsBase = new uint256[](1);
        powerPlantsCostsBase[0] = 0;
        uint256[] memory powerPlantsCostsRates = new uint256[](1);
        powerPlantsCostsRates[0] = 0;
        PowerPlants powerPlants = new PowerPlants(
            sanctis,
            energy,
            rewardBase,
            rewardRate,
            0,
            powerPlantsCostsResources,
            powerPlantsCostsBase,
            powerPlantsCostsRates
        );
        sanctis.setAllowed(address(powerPlants), true);

        cheats.startPrank(player, player);

        uint256 reserveBefore = energy.reserve(homeworld);
        powerPlants.create(homeworld);
        assertEq(energy.reserve(homeworld), reserveBefore + rewardBase);
    }

    function testUpgradePowerPlants(
        uint256 delay,
        uint256 rewardBase,
        uint256 rewardRate,
        uint256 levels
    ) public {
        cheats.assume(delay < 10**18);
        cheats.assume(rewardBase > 0 && rewardBase < 10**40);
        cheats.assume(rewardRate > 0 && rewardRate < 10**40);
        cheats.assume(levels > 0 && levels < 10**4);

        IResource[] memory powerPlantsCostsResources = new IResource[](1);
        powerPlantsCostsResources[0] = iron;
        uint256[] memory powerPlantsCostsBase = new uint256[](1);
        powerPlantsCostsBase[0] = 0;
        uint256[] memory powerPlantsCostsRates = new uint256[](1);
        powerPlantsCostsRates[0] = 0;
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

        cheats.startPrank(player, player);

        powerPlants.create(homeworld);

        for (uint256 i; i < levels; i++) {
            cheats.roll(block.number + (i + 1) * delay);

            uint256 reserveBefore = energy.reserve(homeworld);
            powerPlants.upgrade(homeworld);
            assertEq(
                energy.reserve(homeworld),
                reserveBefore + rewardBase + (i + 1) * rewardRate
            );
        }
    }
}
