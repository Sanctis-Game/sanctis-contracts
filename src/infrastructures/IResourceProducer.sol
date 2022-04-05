// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./IInfrastructure.sol";

interface IResourceProducer is IInfrastructure {
    error ExtractorExistence(uint256 planetId);

    function harvest(uint256 planetId) external;

    function lastHarvest(uint256 planetId) external view returns (uint256);

    function currentProduction(uint256 planetId)
        external
        view
        returns (IResource[] memory, uint256[] memory);

    function nextProduction(uint256 planetId)
        external
        view
        returns (IResource[] memory, uint256[] memory);
}
