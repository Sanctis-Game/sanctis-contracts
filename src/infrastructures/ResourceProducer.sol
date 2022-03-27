// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "openzeppelin-contracts/contracts/utils/introspection/IERC165.sol";
import "openzeppelin-contracts/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

import "../interfaces/ISanctis.sol";
import "../interfaces/ICommanders.sol";
import "../interfaces/IPlanets.sol";
import "../interfaces/IResource.sol";
import "../interfaces/IResourceProducer.sol";
import "../SanctisModule.sol";
import "./Infrastructure.sol";

contract ResourceProducer is Infrastructure, IResourceProducer {
    mapping(uint256 => uint256) private _lastHarvests;

    IResource[] internal _rewardsResources;
    uint256[] internal _rewardsBase;
    uint256[] internal _rewardsRates;

    constructor(
        ISanctis sanctis,
        uint256 delay,
        IResource[] memory rewardsResources,
        uint256[] memory rewardsBase,
        uint256[] memory rewardsRates,
        IResource[] memory costsResources,
        uint256[] memory costsBase,
        uint256[] memory costsRates
    ) Infrastructure(sanctis, delay, costsResources, costsBase, costsRates) {
        require(rewardsResources.length == rewardsBase.length && rewardsBase.length == rewardsRates.length, "Rewards mismatch");
        uint256 i;
        for (; i < rewardsBase.length; ++i) {
            _rewardsResources.push(rewardsResources[i]);
            _rewardsBase.push(rewardsBase[i]);
            _rewardsRates.push(rewardsRates[i]);
        }
    }

    /* ========== Extractor interfaces ========== */
    function harvest(uint256 planetId) public {
        if (_infrastructures[planetId].level == 0)
            revert ExtractorExistence({planetId: planetId});

        uint256[] memory harvestable = _production(
            _infrastructures[planetId].level
        );
        _lastHarvests[planetId] = block.number;

        uint i;
        for (; i < harvestable.length; ++i) {
            _rewardsResources[i].mint(planetId, harvestable[i]);
        }
    }

    function characteristics(uint256 planetId)
        external
        view
        returns (Characteristics memory)
    {
        return
            Characteristics({
                level: _infrastructures[planetId].level,
                lastHarvest: _lastHarvests[planetId],
                nextUpgrade: _infrastructures[planetId].lastUpgrade +
                    _upgradeDelay**_infrastructures[planetId].level,
                producedResources: _rewardsResources,
                productionPerBlock: _production(
                    _infrastructures[planetId].level
                ),
                costsResources: _costsResources,
                nextCosts: _costsAtLevel(_infrastructures[planetId].level)
            });
    }

    /* ========== Infrastructure hooks ========== */
    function _beforeCreation(uint256 planetId) internal override {
        _planetHasResource(planetId);

        _lastHarvests[planetId] = block.number;
    }

    function _beforeUpgrade(uint256 planetId) internal override {
        harvest(planetId);
        _lastHarvests[planetId] = block.number + _upgradeDelay;
    }

    /* ========== Helpers ========== */
    function _planetHasResource(uint256 planetId) internal view {
        uint256 i;
        for (; i < _rewardsBase.length; ++i)
            if (!_rewardsResources[i].isAvailableOnPlanet(planetId))
                revert ResourceNotOnPlanet({
                    planetId: planetId,
                    resource: _rewardsResources[i]
                });
    }

    function _production(uint256 infraLevel)
        internal
        view
        returns (uint256[] memory)
    {
        uint256[] memory production = _rewardsBase;
        uint256 i;
        for (; i < production.length; ++i) {
            production[i] += infraLevel * _rewardsRates[i];
        }
        return production;
    }
}
