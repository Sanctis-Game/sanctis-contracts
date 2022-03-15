// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "openzeppelin-contracts/contracts/utils/introspection/IERC165.sol";
import "openzeppelin-contracts/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

import "../interfaces/ISanctis.sol";
import "../interfaces/ICommanders.sol";
import "../interfaces/IPlanets.sol";
import "../interfaces/IGalacticStandards.sol";
import "../interfaces/IShipRegistry.sol";
import "../interfaces/IFleets.sol";
import "../interfaces/ITransporters.sol";

contract Ship is IShip {
    /// @notice Amount of ships on a given planet
    mapping(uint256 => uint256) internal _reserves;
    /// @notice Amount of ship in a given fleet
    mapping(uint256 => uint256) internal _fleets;

    ISanctis public sanctis;

    uint256 internal _id;
    uint256 internal _speed;
    Cost[] internal _unitCosts;

    constructor(
        ISanctis newSanctis,
        uint256 speed,
        Cost[] memory costs
    ) {
        sanctis = newSanctis;
        _speed = speed;
        _id = sanctis.shipRegistry().create(this);

        uint256 i;
        for(; i<costs.length; ++i) {
            _unitCosts.push(costs[i]);
        }
    }

    /* ========== Ship interfaces ========== */
    function id() external view returns (uint256) {
        return _id;
    }

    function unitCosts() external view returns (Cost[] memory) {
        return _unitCosts;
    }

    function reserve(uint256 planetId) external view returns (uint256) {
        return _reserves[planetId];
    }

    function inFleet(uint256 fleetId) external view returns (uint256) {
        return _fleets[fleetId];
    }

    function build(
        uint256 operatorId,
        uint256 planetId,
        uint256 amount
    ) external {
        _checkIsRegisteredInfrastructure(msg.sender, operatorId);

        // Pay the unit
        uint256 i;
        for (; i < _unitCosts.length; ++i) {
            sanctis.resourceRegistry().resource(_unitCosts[i].resourceId).burn(
                _id,
                planetId,
                _unitCosts[i].quantity * amount
            );
        }

        _reserves[planetId] += amount;
    }

    function destroy(
        uint256 operatorId,
        uint256 planetId,
        uint256 amount
    ) external {
        _checkIsRegisteredInfrastructure(msg.sender, operatorId);

        _reserves[planetId] -= amount;
    }

    function addToFleet(
        uint256 fleetId,
        uint256 planetId,
        uint256 amount
    ) public {
        _checkAuthorizedPlayer(msg.sender, planetId);
        _checkFleetIsOnPlanet(fleetId, planetId);

        _reserves[planetId] -= amount;
        _fleets[fleetId] += amount;
    }

    function removeFromFleet(
        uint256 fleetId,
        uint256 planetId,
        uint256 amount
    ) public {
        _checkAuthorizedPlayer(msg.sender, planetId);
        _checkFleetIsOnPlanet(fleetId, planetId);

        _reserves[planetId] += amount;
        _fleets[fleetId] -= amount;
    }

    /* ========== Helpers ========== */
    function _checkIsPlanetOwner(address player, uint256 planetId)
        internal
        view
    {
        if (
            player !=
            sanctis.commanders().ownerOf(
                sanctis.planets().planet(planetId).ruler
            )
        ) revert PlanetNotOwned({player: player, planet: planetId});
    }

    function _checkAuthorizedPlayer(address player, uint256 planetId)
        internal
        view
    {
        if (
            player !=
            sanctis.commanders().ownerOf(
                sanctis.planets().planet(planetId).ruler
            ) &&
            !sanctis.commanders().isApprovedForAll(
                sanctis.commanders().ownerOf(
                    sanctis.planets().planet(planetId).ruler
                ),
                player
            )
        ) revert UnauthorizedPlayer({player: player, planet: planetId});
    }

    function _checkFleetIsOnPlanet(uint256 fleetId, uint256 planetId)
        internal
        view
    {
        IFleets.Fleet memory f = sanctis.fleets().fleet(fleetId);
        if (
            (f.fromPlanetId == planetId &&
                f.status == IFleets.FleetStatus.Preparing) ||
            (f.toPlanetId == planetId &&
                f.status == IFleets.FleetStatus.Arrived)
        ) revert InvalidFleet({fleet: fleetId});
    }

    function _checkIsRegisteredInfrastructure(
        address sender,
        uint256 infrastructureId
    ) internal view {
        if (
            address(
                sanctis.infrastructureRegistry().infrastructure(
                    infrastructureId
                )
            ) != sender
        ) revert UnauthorizedOperator({operator: infrastructureId});
    }
}
