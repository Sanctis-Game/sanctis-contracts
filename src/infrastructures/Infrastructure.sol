// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "openzeppelin-contracts/contracts/utils/introspection/IERC165.sol";
import "openzeppelin-contracts/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

import "../interfaces/ISanctis.sol";
import "../interfaces/ICommanders.sol";
import "../interfaces/IPlanets.sol";
import "../interfaces/IResource.sol";
import "../interfaces/IInfrastructure.sol";
import "../SanctisModule.sol";

contract Infrastructure is IInfrastructure, SanctisModule {
    /* ========== Sanctis extensions used ========== */
    string constant COMMANDERS = "COMMANDERS";
    string constant PLANETS = "PLANETS";

    /* ========== Contract variables ========== */
    struct BaseInfrastructure {
        uint256 level;
        uint256 lastUpgrade;
    }

    mapping(uint256 => BaseInfrastructure) internal _infrastructures;
    uint256 internal _upgradeDelay;
    IResource[] internal _costsResources;
    uint256[] internal _costsBase;
    uint256[] internal _costsRates;

    constructor(
        ISanctis sanctis,
        uint256 delay,
        IResource[] memory costResources,
        uint256[] memory costsBase,
        uint256[] memory costsRates
    ) SanctisModule(sanctis) {
        _upgradeDelay = delay;

        uint256 i;
        for (; i < costsBase.length; ++i) {
            _costsResources.push(costResources[i]);
            _costsBase.push(costsBase[i]);
            _costsRates.push(costsRates[i]);
        }
    }

    /* ========== Infrastructure interfaces ========== */
    function create(uint256 planetId) external {
        _isPlanetOwner(msg.sender, planetId);
        _planetIsUpgradable(planetId);

        _beforeCreation(planetId);

        _infrastructures[planetId] = BaseInfrastructure({
            level: 1,
            lastUpgrade: 0
        });

        uint256[] memory costs = _costsBase;
        for (uint256 i = 0; i < costs.length; i++) {
            _costsResources[i].burn(planetId, costs[i]);
        }
    }

    function upgrade(uint256 planetId) external {
        _isPlanetOwner(msg.sender, planetId);
        _planetIsUpgradable(planetId);
        _assertInfrastructureExists(planetId);

        _beforeUpgrade(planetId);

        _infrastructures[planetId].level += 1;
        _infrastructures[planetId].lastUpgrade = block.number;

        for (uint256 i = 0; i < _costsBase.length; i++) {
            _costsResources[i].burn(
                planetId,
                _costsBase[i] +
                    _costsRates[i] *
                    _infrastructures[planetId].level
            );
        }
    }

    function level(uint256 planetId) external view returns (uint256) {
        return _infrastructures[planetId].level;
    }

    function costsNextLevel(uint256 planetId)
        external
        view
        returns (IResource[] memory, uint256[] memory)
    {
        return (_costsResources, _costsAtLevel(_infrastructures[planetId].level));
    }

    /* ========== Helpers ========== */
    function _costsAtLevel(uint256 currentLevel)
        internal
        view
        returns (uint256[] memory)
    {
        uint256[] memory costs = _costsBase;
        uint256[] memory lastCosts = currentLevel == 0
            ? new uint256[](costs.length)
            : _costsAtLevel(currentLevel - 1);

        uint256 j;
        for (; j < costs.length; ++j) {
            costs[j] +=
                currentLevel *
                _costsRates[j] +
                lastCosts[0];
        }

        return costs;
    }

    function _assertInfrastructureExists(uint256 planetId) internal view {
        if (_infrastructures[planetId].level == 0)
            revert InfrastructureDoesNotExist({
                infrastructure: address(this),
                planetId: planetId
            });
    }

    function _isPlanetOwner(address operator, uint256 planetId) internal view {
        if (
            operator !=
            ICommanders(sanctis.extension(COMMANDERS)).ownerOf(
                IPlanets(sanctis.extension(PLANETS)).planet(planetId).ruler
            ) &&
            ICommanders(sanctis.extension(COMMANDERS)).isApprovedForAll(
                operator,
                address(this)
            )
        ) revert PlanetNotOwned({planetId: planetId});
    }

    function _planetIsUpgradable(uint256 planetId) internal view {
        uint256 soonestUpgrade = _infrastructures[planetId].lastUpgrade +
            _upgradeDelay *
            _infrastructures[planetId].level;
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
