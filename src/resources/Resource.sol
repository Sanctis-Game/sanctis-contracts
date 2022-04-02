// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "openzeppelin-contracts/contracts/utils/introspection/IERC165.sol";
import "openzeppelin-contracts/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

import "../SanctisModule.sol";
import "./IResource.sol";

/**
 * Contract defining a base for resource handling
 */
contract Resource is SanctisModule, IResource {
    mapping(uint256 => uint256) internal _reserves;

    string internal _name;
    string internal _symbol;

    constructor(ISanctis sanctis_, string memory name_, string memory symbol_) SanctisModule(sanctis_) {
        _name = name_;
        _symbol = symbol_;
    }

    /* ========== Resource interfaces ========== */
    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    /**
     * @notice Let's an infrastructure or ship mint a resource to a specific planet
     * This is useful for resource transportation and consumption for building.
     * @dev Cannot be called by an unregistered operator.
     */
    function mint(
        uint256 planetId,
        uint256 amount
    ) virtual external onlyAllowed {
        _reserves[planetId] += amount;
    }

    function burn(
        uint256 planetId,
        uint256 amount
    ) virtual external onlyAllowed {
        _reserves[planetId] -= amount;
    }

    /// @dev Overload this function to affect rarity of the resource
    function isAvailableOnPlanet(uint256) external pure returns (bool) {
        return true;
    }

    function reserve(uint256 planetId) external view returns (uint256) {
        return _reserves[planetId];
    }
}
