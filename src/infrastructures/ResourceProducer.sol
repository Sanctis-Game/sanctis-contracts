// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "openzeppelin-contracts/contracts/utils/introspection/IERC165.sol";
import "openzeppelin-contracts/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

import "./Infrastructure.sol";
import "./IResourceProducer.sol";

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
        require(
            rewardsResources.length == rewardsBase.length &&
                rewardsBase.length == rewardsRates.length,
            "Rewards mismatch"
        );
        for (uint256 i = 0; i < rewardsBase.length; i++) {
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
        uint256 elapsedBlocks = block.number - _lastHarvests[planetId];
        _lastHarvests[planetId] = block.number;

        for (uint256 i = 0; i < harvestable.length; i++) {
            _rewardsResources[i].mint(planetId, harvestable[i] * elapsedBlocks);
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
                nextUpgrade: _nextUpgrade(planetId),
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
    }

    /* ========== Helpers ========== */
    function _planetHasResource(uint256 planetId) internal view {
        for (uint256 i = 0; i < _rewardsBase.length; i++)
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
        for (uint256 i = 0; i < production.length; i++) {
            production[i] += infraLevel * _rewardsRates[i];
        }
        return production;
    }
}
