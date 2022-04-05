// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./IInfrastructure.sol";

interface IPowerPlants is IInfrastructure {
    struct PowerPlant {
        uint256 level;
        IResource energy;
        uint256 production;
        IResource[] costsResources;
        uint256[] nextCosts;
        uint256 nextUpgrade;
    }

    function energy() external view returns (IResource);

    function currentProduction(uint256 planetId)
        external
        view
        returns (uint256);

    function nextProduction(uint256 planetId) external view returns (uint256);
}
