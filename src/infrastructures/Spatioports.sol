// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "openzeppelin-contracts/contracts/utils/introspection/IERC165.sol";
import "openzeppelin-contracts/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

import "../interfaces/ISanctis.sol";
import "../interfaces/IResource.sol";
import "../interfaces/ISpatioports.sol";

contract Spatioports is ISpatioports {
    struct InternalSpatioport {
        uint256 level;
        uint256 lastUpgrade;
        uint256 lastHarvest;
    }

    mapping(uint256 => InternalSpatioport) internal _spatioports;

    ISanctis internal sanctis;

    uint256 internal _id;
    uint256 internal _upgradeDelay;
    uint256[][] internal _baseCosts;
    uint256[][] internal _costRates;

    /**
     * @dev _cBase and _cRates are array of couple `(resourceId, amount)`
     * The first index using the 0-Resource is considered to be the end.
     * This allows optimizing subsquent iterations over the costs.
     */
    constructor(
        ISanctis _sanctis,
        uint256 _delay,
        uint256[2][10] memory _cBase,
        uint256[2][10] memory _cRates
    ) {
        sanctis = _sanctis;
        _upgradeDelay = _delay;

        uint256 i = 0;
        while(i < 10 && _cBase[i][0] != 0) {
            _baseCosts.push(_cBase[i]);
            _costRates.push(_cRates[i]);
            i++;
        }

        _id = sanctis.infrastructureRegistry().create(this);
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
        ship.build(_id, planetId, amount);
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
    function id() external view returns (uint256) {
        return _id;
    }

    function create(uint256 planetId) external {
        _isPlanetOwner(msg.sender, planetId);

        _spatioports[planetId] = InternalSpatioport({
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

    function upgrade(uint256 planetId) public {
        _spatioportExists(planetId);
        _isPlanetOwner(msg.sender, planetId);
        _planetHasReserves(planetId);
        _planetIsUpgradable(planetId);

        InternalSpatioport storage e = _spatioports[planetId];
        e.level += 1;
        e.lastUpgrade = block.number;

        uint256[][] memory costs = _baseCosts;
        for (uint256 i = 0; i < costs.length; i++) {
            sanctis.resourceRegistry().resource(costs[i][0]).burn(
                _id,
                planetId,
                costs[i][1] + _costRates[i][1] * _spatioports[planetId].level
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
        returns (uint256[][] memory)
    {
        uint256 extractorLevel = _spatioports[planetId].level;
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

    function _spatioportExists(uint256 planetId) internal view {
        if (_spatioports[planetId].level == 0)
            revert SpatioportExistence({planetId: planetId});
    }

    function _planetHasReserves(uint256 planetId) internal view {
        uint256[][] memory costs = costsNextLevel(planetId);
        for (uint256 i = 0; i < costs.length; i++) {
            if (
                sanctis.resourceRegistry().resource(costs[i][0]).reserve(
                    planetId
                ) < costs[i][1]
            )
                revert NotEnoughResource({
                    planetId: planetId,
                    resourceId: costs[i][0]
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
