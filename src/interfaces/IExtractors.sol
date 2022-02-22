// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "./IInfrastructure.sol";

interface IExtractors is IInfrastructure {
    error ExtractorExistence(uint256 planetId);
    
    struct Extractor {
        uint256 level;
        uint256 productionPerBlock;
        uint256[][] nextCosts;
        uint256 nextUpgrade;
    }

    function harvest(uint256 planetId) external;

    function harvestable(uint256 planetId) external view returns (uint256);

    function extractor(uint256 planetId)
        external
        view
        returns (Extractor memory);
}
