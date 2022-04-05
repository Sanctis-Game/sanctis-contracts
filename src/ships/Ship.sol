// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "openzeppelin-contracts/contracts/utils/introspection/IERC165.sol";
import "openzeppelin-contracts/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

import "../SanctisModule.sol";
import "./IShip.sol";

contract Ship is SanctisModule, IShip {
    /* ========== Contract variables ========== */
    /// @notice Amount of ships on a given planet
    mapping(uint256 => uint256) internal s_reserves;
    /// @notice Amount of ship in a given fleet
    mapping(uint256 => uint256) internal s_fleets;
    uint256 internal s_speed;
    uint256 internal s_offensivePower;
    uint256 internal s_defensivePower;
    uint256 internal s_capacity;
    IResource[] internal s_costsResources;
    uint256[] internal s_unitCosts;

    constructor(
        ISanctis newSanctis,
        uint256 speed_,
        uint256 offensivePower_,
        uint256 defensivePower_,
        uint256 capacity_,
        IResource[] memory costsResources,
        uint256[] memory costs
    ) SanctisModule(newSanctis) {
        s_speed = speed_;
        s_offensivePower = offensivePower_;
        s_defensivePower = defensivePower_;
        s_capacity = capacity_;

        for (uint256 i; i < costs.length; i++) {
            s_costsResources.push(costsResources[i]);
            s_unitCosts.push(costs[i]);
        }
    }

    /* ========== Ship interfaces ========== */
    function speed() external view returns (uint256) {
        return s_speed;
    }

    function offensivePower() external view returns (uint256) {
        return s_offensivePower;
    }

    function defensivePower() external view returns (uint256) {
        return s_defensivePower;
    }

    function capacity() external view returns (uint256) {
        return s_capacity;
    }

    function unitCosts()
        external
        view
        returns (IResource[] memory, uint256[] memory)
    {
        return (s_costsResources, s_unitCosts);
    }

    function reserve(uint256 planetId) external view returns (uint256) {
        return s_reserves[planetId];
    }

    function mint(uint256 planetId, uint256 amount) public onlyAllowed {
        s_reserves[planetId] += amount;
    }

    function burn(uint256 planetId, uint256 amount) public onlyAllowed {
        s_reserves[planetId] -= amount;
    }
}
