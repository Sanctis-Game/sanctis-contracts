// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./IResource.sol";

error ResourceZero();

interface IResourceRegistry {
    function create(IResource newResource) external returns (uint256);

    function resource(uint256 resourceId) external view returns (IResource);

    function registeredResources() external view returns (uint256);
}
