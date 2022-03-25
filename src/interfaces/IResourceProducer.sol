// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./IInfrastructure.sol";
import "./Quantity.sol";

interface IResourceProducer is IInfrastructure {
    error ExtractorExistence(uint256 planetId);

    struct Characteristics {
        uint256 level;
        uint256 lastHarvest;
        uint256 nextUpgrade;
        Quantity[] productionPerBlock;
        Quantity[] nextCosts;
    }

    function harvest(uint256 planetId) external;

    function characteristics(uint256 planetId)
        external
        view
        returns (Characteristics memory);
}
