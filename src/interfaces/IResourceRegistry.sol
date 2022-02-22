// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "./IResource.sol";

error ResourceZero();

interface IResourceRegistry {
    function create(IResource newResource) external returns (uint256);

    function resource(uint256 resourceId) external view returns (IResource);

    function registeredResources() external view returns (uint256);
}
