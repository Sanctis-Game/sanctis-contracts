// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "../ISanctisModule.sol";
import "../resources/IResource.sol";

interface IInfrastructure is ISanctisModule {
    function level(uint256 planetId) external view returns (uint256);

    function nextUpgrade(uint256 planetId) external view returns (uint256);

    function costs(uint256 planetId)
        external
        view
        returns (IResource[] memory, uint256[] memory);

    function create(uint256 planetId) external;

    function upgrade(uint256 planetId) external;
}
