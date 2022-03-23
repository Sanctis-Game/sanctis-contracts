// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "openzeppelin-contracts/contracts/utils/introspection/IERC165.sol";
import "openzeppelin-contracts/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

import "../interfaces/Cost.sol";
import "../interfaces/ISanctis.sol";
import "../interfaces/ICommanders.sol";
import "../interfaces/IPlanets.sol";
import "../interfaces/IResource.sol";
import "../interfaces/IExtractors.sol";
import "../SanctisModule.sol";
import "./Infrastructure.sol";

contract Extractors is Infrastructure, IExtractors {
    mapping(uint256 => uint256) private _lastHarvests;

    IResource private _harvestedResource;
    uint256 private _baseRewards;
    uint256 private _rewardsRate;
    uint256 private _levelFactor;

    constructor(
        ISanctis sanctis,
        IResource _resource,
        uint256 rewardBase,
        uint256 rewardRate,
        uint256 delay,
        Cost[] memory baseCosts,
        Cost[] memory costRates
    ) Infrastructure(sanctis, delay, baseCosts, costRates) {
        _harvestedResource = _resource;
        _baseRewards = rewardBase;
        _rewardsRate = rewardRate;
    }

    /* ========== Extractor interfaces ========== */
    function harvest(uint256 planetId) public {
        if (_infrastructures[planetId].level == 0)
            revert ExtractorExistence({planetId: planetId});

        uint256 extractable = (block.number - _lastHarvests[planetId]) *
            _production(_infrastructures[planetId].level);

        _lastHarvests[planetId] = block.number;

        _harvestedResource.mint(planetId, extractable);
    }

    function harvestable(uint256 planetId) external view returns (uint256) {
        return
            (block.number - _lastHarvests[planetId]) *
            _production(_infrastructures[planetId].level);
    }

    function extractor(uint256 planetId)
        external
        view
        returns (Extractor memory)
    {
        return
            Extractor({
                level: _infrastructures[planetId].level,
                productionPerBlock: _production(
                    _infrastructures[planetId].level
                ),
                lastHarvest: _lastHarvests[planetId],
                nextCosts: _costsAtLevel(_infrastructures[planetId].level),
                nextUpgrade: _infrastructures[planetId].lastUpgrade +
                    _upgradeDelay**_infrastructures[planetId].level
            });
    }

    /* ========== Infrastructure hooks ========== */
    function _beforeCreation(uint256 planetId) internal override {
        _planetHasResource(planetId);

        _lastHarvests[planetId] = block.number;
    }

    function _beforeUpgrade(uint256 planetId) internal override {
        _planetHasResource(planetId);

        harvest(planetId);
        _lastHarvests[planetId] = block.number + _upgradeDelay;
    }

    /* ========== Helpers ========== */
    function _planetHasResource(uint256 planetId) internal view {
        if (!_harvestedResource.isAvailableOnPlanet(planetId))
            revert ResourceNotOnPlanet({
                planetId: planetId,
                resource: _harvestedResource
            });
    }

    function _production(uint256 infraLevel) internal view returns (uint256) {
        return _baseRewards + infraLevel * _rewardsRate;
    }
}
