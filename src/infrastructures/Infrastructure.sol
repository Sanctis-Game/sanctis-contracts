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
    Quantity[] internal _baseCosts;
    Quantity[] internal _costRates;

    constructor(
        ISanctis sanctis,
        uint256 delay,
        Quantity[] memory baseCosts,
        Quantity[] memory costRates
    ) SanctisModule(sanctis) {
        _upgradeDelay = delay;

        uint256 i;
        for (; i < baseCosts.length; ++i) {
            _baseCosts.push(baseCosts[i]);
            _costRates.push(costRates[i]);
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

        Quantity[] memory costs = _baseCosts;
        for (uint256 i = 0; i < costs.length; i++) {
            costs[i].resource.burn(planetId, costs[i].quantity);
        }
    }

    function upgrade(uint256 planetId) external {
        _isPlanetOwner(msg.sender, planetId);
        _planetIsUpgradable(planetId);
        _assertInfrastructureExists(planetId);

        _beforeUpgrade(planetId);

        _infrastructures[planetId].level += 1;
        _infrastructures[planetId].lastUpgrade = block.number;

        for (uint256 i = 0; i < _baseCosts.length; i++) {
            _baseCosts[i].resource.burn(
                planetId,
                _baseCosts[i].quantity +
                    _costRates[i].quantity *
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
        returns (Quantity[] memory)
    {
        return _costsAtLevel(_infrastructures[planetId].level);
    }

    /* ========== Helpers ========== */
    function _costsAtLevel(uint256 currentLevel)
        internal
        view
        returns (Quantity[] memory)
    {
        Quantity[] memory costs = _baseCosts;
        Quantity[] memory lastCosts = currentLevel == 0
            ? new Quantity[](costs.length)
            : _costsAtLevel(currentLevel - 1);

        uint256 j;
        for (; j < costs.length; ++j) {
            costs[j].quantity +=
                currentLevel *
                _costRates[j].quantity +
                lastCosts[0].quantity;
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
