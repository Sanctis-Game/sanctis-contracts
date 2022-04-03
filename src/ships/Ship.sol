// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "openzeppelin-contracts/contracts/utils/introspection/IERC165.sol";
import "openzeppelin-contracts/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

import "../SanctisModule.sol";
import "./IShip.sol";

contract Ship is SanctisModule, IShip {
    /// @notice Amount of ships on a given planet
    mapping(uint256 => uint256) internal _reserves;
    /// @notice Amount of ship in a given fleet
    mapping(uint256 => uint256) internal _fleets;

    uint256 internal _speed;
    uint256 internal _offensivePower;
    uint256 internal _defensivePower;
    uint256 internal _capacity;
    IResource[] internal _costsResources;
    uint256[] internal _unitCosts;

    constructor(
        ISanctis newSanctis,
        uint256 speed_,
        uint256 offensivePower_,
        uint256 defensivePower_,
        uint256 capacity_,
        IResource[] memory costsResources,
        uint256[] memory costs
    ) SanctisModule(newSanctis) {
        _speed = speed_;
        _offensivePower = offensivePower_;
        _defensivePower = defensivePower_;
        _capacity = capacity_;

        for (uint256 i; i < costs.length; i++) {
            _costsResources.push(costsResources[i]);
            _unitCosts.push(costs[i]);
        }
    }

    /* ========== Ship interfaces ========== */
    function speed() external view returns (uint256) {
        return _speed;
    }

    function offensivePower() external view returns (uint256) {
        return _offensivePower;
    }

    function defensivePower() external view returns (uint256) {
        return _defensivePower;
    }

    function capacity() external view returns (uint256) {
        return _capacity;
    }

    function unitCosts()
        external
        view
        returns (IResource[] memory, uint256[] memory)
    {
        return (_costsResources, _unitCosts);
    }

    function reserve(uint256 planetId) external view returns (uint256) {
        return _reserves[planetId];
    }

    function mint(uint256 planetId, uint256 amount) public onlyAllowed {
        _reserves[planetId] += amount;
    }

    function burn(uint256 planetId, uint256 amount) public onlyAllowed {
        _reserves[planetId] -= amount;
    }
}
