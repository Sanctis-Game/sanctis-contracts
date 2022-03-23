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
import "../interfaces/ISpatioports.sol";
import "../SanctisModule.sol";

contract Spatioports is ISpatioports, SanctisModule {
    /* ========== Sanctis extensions used ========== */
    string constant COMMANDERS = "COMMANDERS";
    string constant CREDITS = "CREDITS";

    /* ========== Sanctis extensions used ========== */
    /// @dev Compact struct which can be used to infer other info
    struct InternalSpatioport {
        uint256 level;
        uint256 lastUpgrade;
        uint256 lastHarvest;
    }
    
    mapping(uint256 => InternalSpatioport) internal _spatioports;
    uint256 internal _upgradeDelay;
    Cost[] internal _baseCosts;
    Cost[] internal _costRates;

    /**
     * @dev _cBase and _cRates are array of couple `(resourceId, amount)`
     * The first index using the 0-Resource is considered to be the end.
     * This allows optimizing subsquent iterations over the costs.
     */
    constructor(
        ISanctis _sanctis,
        uint256 _delay,
        Cost[] memory _cBase,
        Cost[] memory _cRates
    ) SanctisModule(_sanctis) {
        _upgradeDelay = _delay;

        uint256 i;
        for (; i < _cBase.length; ++i) {
            _baseCosts.push(_cBase[i]);
            _costRates.push(_cRates[i]);
        }
    }

    /* ========== Spatioport interfaces ========== */
    function build(
        uint256 planetId,
        IShip ship,
        uint256 amount
    ) external {
        _spatioportExists(planetId);
        _isPlanetOwner(msg.sender, planetId);

        // Costs are handled by the ship
        ship.build(planetId, amount);
    }

    function spatioport(uint256 planetId)
        public
        view
        returns (Spatioport memory)
    {
        InternalSpatioport memory e = _spatioports[planetId];
        return
            Spatioport({
                level: e.level,
                nextCosts: costsNextLevel(planetId),
                nextUpgrade: _timeForUpgrade(planetId)
            });
    }

    /* ========== Infrastructure interfaces ========== */
    function create(uint256 planetId) external {
        _isPlanetOwner(msg.sender, planetId);

        _spatioports[planetId] = InternalSpatioport({
            level: 1,
            lastUpgrade: 0,
            lastHarvest: block.number
        });

        Cost[] memory costs = _baseCosts;
        for (uint256 i = 0; i < costs.length; i++) {
            costs[i].resource.burn(
                planetId,
                costs[i].quantity
            );
        }
    }

    function upgrade(uint256 planetId) public {
        _spatioportExists(planetId);
        _isPlanetOwner(msg.sender, planetId);
        _planetHasReserves(planetId);
        _planetIsUpgradable(planetId);

        InternalSpatioport storage e = _spatioports[planetId];
        e.level += 1;
        e.lastUpgrade = block.number;

        Cost[] memory costs = _baseCosts;
        for (uint256 i = 0; i < costs.length; i++) {
            costs[i].resource.burn(
                planetId,
                costs[i].quantity +
                    _costRates[i].quantity *
                    _spatioports[planetId].level
            );
        }
    }

    function level(uint256 planetId) external view returns (uint256) {
        return _spatioports[planetId].level;
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
        uint256 extractorLevel = _spatioports[planetId].level;
        Cost[] memory costs = _baseCosts;
        Cost[] memory rates = _costRates;

        for (uint256 j = 0; j < _baseCosts.length; j++) {
            costs[j].quantity += extractorLevel * rates[j].quantity;
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

    function _spatioportExists(uint256 planetId) internal view {
        if (_spatioports[planetId].level == 0)
            revert SpatioportExistence({planetId: planetId});
    }

    function _planetHasReserves(uint256 planetId) internal view {
        Cost[] memory costs = costsNextLevel(planetId);
        for (uint256 i = 0; i < costs.length; i++) {
            if (costs[i].resource.reserve(planetId) < costs[i].quantity)
                revert NotEnoughResource({
                    planetId: planetId,
                    resource: costs[i].resource
                });
        }
    }

    function _planetIsUpgradable(uint256 planetId) internal view {
        uint256 soonestUpgrade = _timeForUpgrade(planetId);
        if (block.number < soonestUpgrade)
            revert TooSoonToUpgrade({
                planetId: planetId,
                soonestUpgrade: soonestUpgrade
            });
    }

    function _timeForUpgrade(uint256 planetId) internal view returns (uint256) {
        return
            _spatioports[planetId].lastUpgrade +
            _upgradeDelay *
            _spatioports[planetId].level;
    }
}
