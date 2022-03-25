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
import "../interfaces/IResourceProducer.sol";
import "../SanctisModule.sol";
import "./Infrastructure.sol";

contract ResourceProducer is Infrastructure, IResourceProducer {
    mapping(uint256 => uint256) private _lastHarvests;

    Quantity[] internal _rewardsBase;
    Quantity[] internal _rewardsRate;

    constructor(
        ISanctis sanctis,
        uint256 delay,
        Quantity[] memory rewardsBase,
        Quantity[] memory rewardsRate,
        Quantity[] memory baseCosts,
        Quantity[] memory costRates
    ) Infrastructure(sanctis, delay, baseCosts, costRates) {
        uint256 i;
        for (; i < rewardsBase.length; ++i) {
            require(
                rewardsBase[i].resource == rewardsRate[i].resource,
                "Base+rate mismatch"
            );
            _rewardsBase.push(rewardsBase[i]);
            _rewardsRate.push(rewardsRate[i]);
        }
    }

    /* ========== Extractor interfaces ========== */
    function harvest(uint256 planetId) public {
        if (_infrastructures[planetId].level == 0)
            revert ExtractorExistence({planetId: planetId});

        Quantity[] memory harvestable = _production(
            _infrastructures[planetId].level
        );
        _lastHarvests[planetId] = block.number;

        uint i;
        for (; i < harvestable.length; ++i) {
            harvestable[i].resource.mint(planetId, harvestable[i].quantity);
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
                productionPerBlock: _production(
                    _infrastructures[planetId].level
                ),
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
            if (!_rewardsBase[i].resource.isAvailableOnPlanet(planetId))
                revert ResourceNotOnPlanet({
                    planetId: planetId,
                    resource: _rewardsBase[i].resource
                });
    }

    function _production(uint256 infraLevel)
        internal
        view
        returns (Quantity[] memory)
    {
        Quantity[] memory production = _rewardsBase;
        uint256 i;
        for (; i < production.length; ++i) {
            production[i].quantity += infraLevel * _rewardsRate[i].quantity;
        }
        return production;
    }
}
