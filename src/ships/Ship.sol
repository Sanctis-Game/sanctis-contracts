// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "openzeppelin-contracts/contracts/utils/introspection/IERC165.sol";
import "openzeppelin-contracts/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

import "../interfaces/ISanctis.sol";
import "../interfaces/ICommanders.sol";
import "../interfaces/IPlanets.sol";
import "../interfaces/IFleets.sol";
import "../SanctisModule.sol";

contract Ship is IShip, SanctisModule {
    /// @notice Amount of ships on a given planet
    mapping(uint256 => uint256) internal _reserves;
    /// @notice Amount of ship in a given fleet
    mapping(uint256 => uint256) internal _fleets;

    uint256 internal _speed;
    uint256 internal _offensivePower;
    uint256 internal _defensivePower;
    uint256 internal _capacity;
    Cost[] internal _unitCosts;

    constructor(
        ISanctis newSanctis,
        uint256 speed_,
        uint256 offensivePower_,
        uint256 defensivePower_,
        uint256 capacity_,
        Cost[] memory costs
    ) SanctisModule(newSanctis) {
        _speed = speed_;
        _offensivePower = offensivePower_;
        _defensivePower = defensivePower_;
        _capacity = capacity_;

        uint256 i;
        for (; i < costs.length; ++i) {
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

    function unitCosts() external view returns (Cost[] memory) {
        return _unitCosts;
    }

    function reserve(uint256 planetId) external view returns (uint256) {
        return _reserves[planetId];
    }

    function build(uint256 planetId, uint256 amount) external onlyAllowed {
        // Pay the unit
        uint256 i;
        for (; i < _unitCosts.length; ++i) {
            _unitCosts[i].resource.burn(
                planetId,
                _unitCosts[i].quantity * amount
            );
        }

        mint(planetId, amount);
    }

    function destroy(uint256 planetId, uint256 amount) external onlyAllowed {
        // TODO: Refunds

        burn(planetId, amount);
    }

    function mint(uint256 planetId, uint256 amount) public onlyAllowed {
        _reserves[planetId] += amount;
    }

    function burn(uint256 planetId, uint256 amount) public onlyAllowed {
        _reserves[planetId] -= amount;
    }
}
