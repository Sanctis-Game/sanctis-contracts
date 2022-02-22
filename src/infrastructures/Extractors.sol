// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "openzeppelin-contracts/contracts/utils/introspection/IERC165.sol";
import "openzeppelin-contracts/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

import "../interfaces/ISanctis.sol";
import "../interfaces/ICommanders.sol";
import "../interfaces/IPlanets.sol";
import "../interfaces/IResourceRegistry.sol";
import "../interfaces/IInfrastructureRegistry.sol";
import "../interfaces/IResource.sol";
import "../interfaces/IExtractors.sol";

contract Extractors is IExtractors {
    struct InternalExtractor {
        uint256 level;
        uint256 lastUpgrade;
        uint256 lastHarvest;
    }

    mapping(uint256 => InternalExtractor) private _extractors;

    ISanctis public sanctis;

    uint256 private _id;
    uint256 private _harvestedResource;
    uint256 private _baseRewards;
    uint256 private _rewardsRate;
    uint256 private _levelFactor;
    uint256 private _upgradeDelay;
    uint256[][] private _baseCosts;
    uint256[][] private _costRates;

    /**
     * @dev _cBase and _cRates are array of couple `(resourceId, amount)`
     * The first index using the 0-Resource is considered to be the end.
     * This allows optimizing subsquent iterations over the costs.
     */
    constructor(
        ISanctis _sanctis,
        uint256 _resourceId,
        uint256 _rBase,
        uint256 _rRate,
        uint256 _delay,
        uint256[2][10] memory _cBase,
        uint256[2][10] memory _cRates
    ) {
        if (_resourceId == 0) revert ResourceZero();

        sanctis = _sanctis;
        _harvestedResource = _resourceId;
        _baseRewards = _rBase;
        _rewardsRate = _rRate;
        _upgradeDelay = _delay;

        uint256 i = 0;
        while (i < 10 && _cBase[i][0] != 0) {
            _baseCosts.push(_cBase[i]);
            _costRates.push(_cRates[i]);
            i++;
        }

        _id = sanctis.infrastructureRegistry().create(this);
    }

    /* ========== Extractor interfaces ========== */
    function harvest(uint256 planetId) public {
        InternalExtractor memory e = _extractors[planetId];
        if (e.level == 0) revert ExtractorExistence({planetId: planetId});

        uint256 extractable = (block.number - e.lastHarvest) *
            _production(e.level);

        _extractors[planetId].lastHarvest = block.number;

        sanctis.resourceRegistry().resource(_harvestedResource).mint(
            _id,
            planetId,
            extractable
        );
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
                nextCosts: this.costsNextLevel(planetId),
                nextUpgrade: e.lastUpgrade + _upgradeDelay**e.level
            });
    }

    /* ========== Infrastructure interfaces ========== */
    function id() external view returns (uint256) {
        return _id;
    }

    function create(uint256 planetId) external {
        _isPlanetOwner(msg.sender, planetId);
        _planetHasResource(planetId);
        _planetIsUpgradable(planetId);

        _extractors[planetId] = InternalExtractor({
            level: 1,
            lastUpgrade: 0,
            lastHarvest: block.number
        });

        uint256[][] memory costs = _baseCosts;
        for (uint256 i = 0; i < costs.length; i++) {
            sanctis.resourceRegistry().resource(costs[i][0]).burn(
                _id,
                planetId,
                costs[i][1]
            );
        }
    }

    function upgrade(uint256 planetId) external {
        _isPlanetOwner(msg.sender, planetId);
        _planetHasResource(planetId);
        _planetIsUpgradable(planetId);

        harvest(planetId);
        InternalExtractor storage e = _extractors[planetId];
        e.level += 1;
        e.lastUpgrade = block.number;
        e.lastHarvest = block.number + _upgradeDelay;

        uint256[][] memory costs = _baseCosts;
        for (uint256 i = 0; i < costs.length; i++) {
            sanctis.resourceRegistry().resource(costs[i][0]).burn(
                _id,
                planetId,
                costs[i][1] + _costRates[i][1] * _extractors[planetId].level
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
        external
        view
        returns (uint256[][] memory)
    {
        uint256 extractorLevel = _extractors[planetId].level;
        uint256[][] memory costs = _baseCosts;
        uint256[][] memory rates = _costRates;

        for (uint256 j = 0; j < _baseCosts.length; j++) {
            costs[j][1] += extractorLevel * rates[j][1];
        }

        return costs;
    }

    /* ========== Helpers ========== */
    function _isPlanetOwner(address operator, uint256 planetId) internal view {
        if (
            operator !=
            sanctis.commanders().ownerOf(
                sanctis.planets().planet(planetId).ruler
            ) &&
            sanctis.commanders().isApprovedForAll(operator, address(this))
        ) revert PlanetNotOwned({planetId: planetId});
    }

    function _planetHasResource(uint256 planetId) internal view {
        if (
            !sanctis
                .resourceRegistry()
                .resource(_harvestedResource)
                .isAvailableOnPlanet(planetId)
        )
            revert ResourceNotOnPlanet({
                planetId: planetId,
                resourceId: _harvestedResource
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
