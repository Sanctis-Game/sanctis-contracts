// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./IInfrastructure.sol";
import "./Cost.sol";

interface IExtractors is IInfrastructure {
    error ExtractorExistence(uint256 planetId);

    struct Extractor {
        uint256 level;
        uint256 productionPerBlock;
        uint256 lastHarvest;
        Cost[] nextCosts;
        uint256 nextUpgrade;
    }

    function harvest(uint256 planetId) external;

    function harvestable(uint256 planetId) external view returns (uint256);

    function extractor(uint256 planetId)
        external
        view
        returns (Extractor memory);
}
