// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "openzeppelin-contracts/contracts/utils/introspection/IERC165.sol";
import "openzeppelin-contracts/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

import "./interfaces/ICommanders.sol";
import "./interfaces/IResourceRegistry.sol";
import "./interfaces/IResource.sol";

contract ResourceRegistry is IResourceRegistry {
    mapping(uint256 => IResource) private _resources;
    uint256 private _registeredResources;

    function create(IResource newResource) external returns (uint256) {
        _registeredResources++;
        _resources[_registeredResources] = newResource;
        return _registeredResources;
    }

    function resource(uint256 resourceId) external view returns (IResource) {
        return _resources[resourceId];
    }

    function registeredResources() external view returns (uint256) {
        return _registeredResources;
    }
}
