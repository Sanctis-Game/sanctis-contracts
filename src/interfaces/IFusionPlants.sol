// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./IInfrastructure.sol";
import "./Cost.sol";

interface IFusionPlants is IInfrastructure {
    struct FusionPlant {
        uint256 level;
        uint256 production;
        Cost[] nextCosts;
        uint256 nextUpgrade;
    }

    function fusionPlant(uint256 planetId)
        external
        view
        returns (FusionPlant memory);
}
