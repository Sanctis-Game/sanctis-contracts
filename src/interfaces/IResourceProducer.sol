// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./IInfrastructure.sol";
import "./IResource.sol";

interface IResourceProducer is IInfrastructure {
    error ExtractorExistence(uint256 planetId);

    struct Characteristics {
        uint256 level;
        uint256 lastHarvest;
        uint256 nextUpgrade;
        IResource[] producedResources;
        uint256[] productionPerBlock;
        IResource[] costsResources;
        uint256[] nextCosts;
    }

    function harvest(uint256 planetId) external;

    function characteristics(uint256 planetId)
        external
        view
        returns (Characteristics memory);
}
