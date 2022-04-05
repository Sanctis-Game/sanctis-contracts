// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "openzeppelin-contracts/contracts/utils/introspection/IERC165.sol";
import "openzeppelin-contracts/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

import "./IInfrastructure.sol";
import "../SanctisModule.sol";
import "../extensions/ICommanders.sol";
import "../extensions/IPlanets.sol";
import "../resources/IResource.sol";

contract Infrastructure is IInfrastructure, SanctisModule {
    /* ========== Sanctis extensions used ========== */
    bytes32 constant COMMANDERS = "COMMANDERS";
    bytes32 constant PLANETS = "PLANETS";

    /* ========== Contract variables ========== */
    struct BaseInfrastructure {
        uint256 level;
        uint256 lastUpgrade;
    }

    mapping(uint256 => BaseInfrastructure) internal s_infrastructures;
    uint256 internal _upgradeDelay;
    IResource[] internal s_costsResources;
    uint256[] internal s_costsBase;
    uint256[] internal s_costsRates;

    constructor(
        ISanctis _sanctis,
        uint256 delay,
        IResource[] memory costResources,
        uint256[] memory costsBase,
        uint256[] memory costsRates
    ) SanctisModule(_sanctis) {
        _upgradeDelay = delay;

        uint256 i;
        for (; i < costsBase.length; ++i) {
            s_costsResources.push(costResources[i]);
            s_costsBase.push(costsBase[i]);
            s_costsRates.push(costsRates[i]);
        }
    }

    /* ========== Infrastructure interfaces ========== */
    function create(uint256 planetId) external {
        require(s_infrastructures[planetId].level == 0, "Already exists");
        _isPlanetOwner(msg.sender, planetId);

        _beforeCreation(planetId);

        s_infrastructures[planetId] = BaseInfrastructure({
            level: 1,
            lastUpgrade: block.number
        });

        uint256[] memory _costs = s_costsBase;
        for (uint256 i = 0; i < _costs.length; i++) {
            s_costsResources[i].burn(planetId, _costs[i]);
        }
    }

    function upgrade(uint256 planetId) external {
        _isPlanetOwner(msg.sender, planetId);
        _planetIsUpgradable(planetId);
        _assertInfrastructureExists(planetId);

        _beforeUpgrade(planetId);

        uint256[] memory _costs = _costsUpgrade(
            s_infrastructures[planetId].level
        );

        s_infrastructures[planetId].level += 1;
        s_infrastructures[planetId].lastUpgrade = block.number;

        uint256 i;
        for (; i < _costs.length; ++i) {
            s_costsResources[i].burn(planetId, _costs[i]);
        }
    }

    function level(uint256 planetId) external view returns (uint256) {
        return s_infrastructures[planetId].level;
    }

    function nextUpgrade(uint256 planetId) external view returns (uint256) {
        return _nextUpgrade(planetId);
    }

    function costs(uint256 planetId)
        external
        view
        returns (IResource[] memory, uint256[] memory)
    {
        return (
            s_costsResources,
            _costsUpgrade(s_infrastructures[planetId].level)
        );
    }

    /* ========== Helpers ========== */
    function _costsUpgrade(uint256 fromLevel)
        internal
        view
        returns (uint256[] memory)
    {
        uint256[] memory _costs = s_costsBase;
        uint256 j;
        for (; j < _costs.length; ++j) {
            _costs[j] =
                _costs[j] +
                fromLevel *
                (_costs[j] + (s_costsRates[j] * fromLevel) / 2);
        }

        return _costs;
    }

    function _nextUpgrade(uint256 planetId) internal view returns (uint256) {
        return
            s_infrastructures[planetId].lastUpgrade +
            _upgradeDelay *
            s_infrastructures[planetId].level;
    }

    function _assertInfrastructureExists(uint256 planetId) internal view {
        if (s_infrastructures[planetId].level == 0)
            revert InfrastructureDoesNotExist({
                infrastructure: address(this),
                planetId: planetId
            });
    }

    function _isPlanetOwner(address operator, uint256 planetId) internal view {
        if (
            !ICommanders(s_sanctis.extension(COMMANDERS)).isApproved(
                operator,
                IPlanets(s_sanctis.extension(PLANETS)).planet(planetId).ruler
            )
        ) revert PlanetNotOwned({planetId: planetId});
    }

    function _planetIsUpgradable(uint256 planetId) internal view {
        uint256 soonestUpgrade = _nextUpgrade(planetId);
        if (block.number < soonestUpgrade)
            revert TooSoonToUpgrade({
                planetId: planetId,
                soonestUpgrade: soonestUpgrade
            });
    }

    /* ========== Hooks ========== */
    function _beforeCreation(uint256 planetId) internal virtual {}

    function _beforeUpgrade(uint256 planetId) internal virtual {}
}
