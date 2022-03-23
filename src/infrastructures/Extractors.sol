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

contract Extractors is IExtractors, SanctisModule {
    struct InternalExtractor {
        uint256 level;
        uint256 lastUpgrade;
        uint256 lastHarvest;
    }

    mapping(uint256 => InternalExtractor) private _extractors;

    IResource private _harvestedResource;
    uint256 private _baseRewards;
    uint256 private _rewardsRate;
    uint256 private _levelFactor;
    uint256 private _upgradeDelay;
    Cost[] private _baseCosts;
    Cost[] private _costRates;

    /**
     * @dev _cBase and _cRates are array of couple `(resourceId, amount)`
     * The first index using the 0-Resource is considered to be the end.
     * This allows optimizing subsquent iterations over the costs.
     */
    constructor(
        ISanctis _sanctis,
        IResource _resource,
        uint256 _rBase,
        uint256 _rRate,
        uint256 _delay,
        Cost[] memory _cBase,
        Cost[] memory _cRates
    ) SanctisModule(_sanctis) {
        _harvestedResource = _resource;
        _baseRewards = _rBase;
        _rewardsRate = _rRate;
        _upgradeDelay = _delay;

        uint256 i;
        for (; i < _cBase.length; ++i) {
            _baseCosts.push(_cBase[i]);
            _costRates.push(_cRates[i]);
        }
    }

    /* ========== Extractor interfaces ========== */
    function harvest(uint256 planetId) public {
        InternalExtractor memory e = _extractors[planetId];
        if (e.level == 0) revert ExtractorExistence({planetId: planetId});

        uint256 extractable = (block.number - e.lastHarvest) *
            _production(e.level);

        _extractors[planetId].lastHarvest = block.number;

        _harvestedResource.mint(planetId, extractable);
    }

    function harvestable(uint256 planetId) external view returns (uint256) {
        InternalExtractor memory e = _extractors[planetId];
        return (block.number - e.lastHarvest) * _production(e.level);
    }

    function extractor(uint256 planetId)
        external
        view
        returns (Extractor memory)
    {
        InternalExtractor memory e = _extractors[planetId];
        return
            Extractor({
                level: e.level,
                productionPerBlock: _production(e.level),
                lastHarvest: e.lastHarvest,
                nextCosts: costsNextLevel(planetId),
                nextUpgrade: e.lastUpgrade + _upgradeDelay**e.level
            });
    }

    /* ========== Infrastructure interfaces ========== */
    function create(uint256 planetId) external {
        _isPlanetOwner(msg.sender, planetId);
        _planetHasResource(planetId);
        _planetIsUpgradable(planetId);

        _extractors[planetId] = InternalExtractor({
            level: 1,
            lastUpgrade: 0,
            lastHarvest: block.number
        });

        Cost[] memory costs = _baseCosts;
        for (uint256 i = 0; i < costs.length; i++) {
            _harvestedResource.burn(planetId, costs[i].quantity);
        }
    }

    function upgrade(uint256 planetId) external {
        _isPlanetOwner(msg.sender, planetId);
        _planetHasResource(planetId);
        _planetIsUpgradable(planetId);

        harvest(planetId);
        _extractors[planetId].level += 1;
        _extractors[planetId].lastUpgrade = block.number;
        _extractors[planetId].lastHarvest = block.number + _upgradeDelay;

        for (uint256 i = 0; i < _baseCosts.length; i++) {
            _baseCosts[i].resource.burn(
                planetId, 
                _baseCosts[i].quantity +
                _costRates[i].quantity *
                _extractors[planetId].level
            );
        }
    }

    function level(uint256 planetId) external view returns (uint256) {
        return _extractors[planetId].level;
    }

    /**
     * @notice The amount of each resources needed to upgrade
     * @return An array of tuple (resourceId, amountNeeded)
     */
    function costsNextLevel(uint256 planetId)
        public
        view
        returns (Cost[] memory)
    {
        Cost[] memory costs = _baseCosts;

        for (uint256 j = 0; j < costs.length; j++) {
            costs[j].quantity += _extractors[planetId].level * _costRates[j].quantity;
        }

        return costs;
    }

    /* ========== Helpers ========== */
    function _isPlanetOwner(address operator, uint256 planetId) internal view {
        if (
            operator !=
            ICommanders(sanctis.extension("COMMANDERS")).ownerOf(
                IPlanets(sanctis.extension("PLANETS")).planet(planetId).ruler
            ) &&
            ICommanders(sanctis.extension("COMMANDERS")).isApprovedForAll(operator, address(this))
        ) revert PlanetNotOwned({planetId: planetId});
    }

    function _planetHasResource(uint256 planetId) internal view {
        if (!_harvestedResource.isAvailableOnPlanet(planetId))
            revert ResourceNotOnPlanet({
                planetId: planetId,
                resource: _harvestedResource
            });
    }

    function _planetIsUpgradable(uint256 planetId) internal view {
        InternalExtractor memory e = _extractors[planetId];
        uint256 soonestUpgrade = e.lastUpgrade + _upgradeDelay * e.level;
        if (block.number < soonestUpgrade)
            revert TooSoonToUpgrade({
                planetId: planetId,
                soonestUpgrade: soonestUpgrade
            });
    }

    function _production(uint256 infraLevel) internal view returns (uint256) {
        return _baseRewards + infraLevel * _rewardsRate;
    }
}
