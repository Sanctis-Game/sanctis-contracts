// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "openzeppelin-contracts/contracts/utils/introspection/IERC165.sol";
import "openzeppelin-contracts/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

import "../interfaces/ISanctis.sol";
import "../interfaces/ICommanders.sol";
import "../interfaces/IPlanets.sol";
import "../interfaces/IResource.sol";
import "../interfaces/IPowerPlants.sol";
import "./Infrastructure.sol";

contract PowerPlants is Infrastructure, IPowerPlants {
    /* ========== Contract variables ========== */
    IResource internal _energy;
    uint256 internal _rewardsBase;
    uint256 internal _rewardsRates;

    constructor(
        ISanctis sanctis,
        IResource energy,
        uint256 rewardsBase,
        uint256 rewardsRates,
        uint256 delay,
        IResource[] memory costsResources,
        uint256[] memory costsBase,
        uint256[] memory costsRates
    ) Infrastructure(sanctis, delay, costsResources, costsBase, costsRates) {
        _energy = energy;
        _rewardsBase = rewardsBase;
        _rewardsRates = rewardsRates;
    }

    /* ========== Power plant interfaces ========== */
    function powerPlant(uint256 planetId)
        external
        view
        returns (PowerPlant memory)
    {
        return
            PowerPlant({
                level: _infrastructures[planetId].level,
                energy: _energy,
                production: _production(_infrastructures[planetId].level),
                costsResources: _costsResources,
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
        return _rewardsBase + infraLevel * _rewardsRates;
    }
}
