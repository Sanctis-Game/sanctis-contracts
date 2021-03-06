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
    /* ========== Contract variables ========== */
    mapping(uint256 => uint256) internal s_reserves;
    string internal s_name;
    string internal s_symbol;

    constructor(
        ISanctis sanctis_,
        string memory name_,
        string memory symbol_
    ) SanctisModule(sanctis_) {
        s_name = name_;
        s_symbol = symbol_;
    }

    /* ========== Resource interfaces ========== */
    function name() external view returns (string memory) {
        return s_name;
    }

    function symbol() external view returns (string memory) {
        return s_symbol;
    }

    /**
     * @notice Let's an infrastructure or ship mint a resource to a specific planet
     * This is useful for resource transportation and consumption for building.
     * @dev Cannot be called by an unregistered operator.
     */
    function mint(uint256 planetId, uint256 amount)
        external
        virtual
        onlyAllowed
    {
        s_reserves[planetId] += amount;
        emit Mint(planetId, amount);
    }

    function burn(uint256 planetId, uint256 amount)
        external
        virtual
        onlyAllowed
    {
        s_reserves[planetId] -= amount;
        emit Burn(planetId, amount);
    }

    /// @dev Overload this function to affect rarity of the resource
    function isAvailableOnPlanet(uint256) external pure returns (bool) {
        return true;
    }

    function reserve(uint256 planetId) external view returns (uint256) {
        return s_reserves[planetId];
    }
}
