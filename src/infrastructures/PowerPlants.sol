// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "openzeppelin-contracts/contracts/utils/introspection/IERC165.sol";
import "openzeppelin-contracts/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

import "../interfaces/Quantity.sol";
import "../interfaces/ISanctis.sol";
import "../interfaces/ICommanders.sol";
import "../interfaces/IPlanets.sol";
import "../interfaces/IResource.sol";
import "../interfaces/IFusionPlants.sol";
import "./Infrastructure.sol";

contract FusionPlants is Infrastructure, IFusionPlants {
    /* ========== Contract variables ========== */
    IResource private _energy;
    uint256 private _baseRewards;
    uint256 private _rewardsRate;

    constructor(
        ISanctis sanctis,
        IResource energy,
        uint256 rewardBase,
        uint256 rewardRate,
        uint256 delay,
        Quantity[] memory costsBase,
        Quantity[] memory costsRates
    ) Infrastructure(sanctis, delay, costsBase, costsRates) {
        _energy = energy;
        _baseRewards = rewardBase;
        _rewardsRate = rewardRate;
    }

    /* ========== Extractor interfaces ========== */
    function fusionPlant(uint256 planetId)
        external
        view
        returns (FusionPlant memory)
    {
        return
            FusionPlant({
                level: _infrastructures[planetId].level,
                production: _production(_infrastructures[planetId].level),
                nextCosts: _costsAtLevel(_infrastructures[planetId].level),
                nextUpgrade: _infrastructures[planetId].lastUpgrade + _upgradeDelay**_infrastructures[planetId].level
            });
    }

    /* ========== Infrastructure interfaces ========== */
    function _beforeCreation(uint256 planetId) internal override {
        _energy.mint(planetId, _production(0));
    }

    function _beforeUpgrade(uint256 planetId) internal override {
        _energy.mint(planetId, _production(_infrastructures[planetId].level));
    }

    /* ========== Helpers ========== */
    function _production(uint256 infraLevel) internal view returns (uint256) {
        return _baseRewards + infraLevel * _rewardsRate;
    }
}
