// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "openzeppelin-contracts/contracts/utils/introspection/IERC165.sol";
import "openzeppelin-contracts/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

import "../SanctisModule.sol";
import "./IPlundering.sol";
import "../extensions/ICommanders.sol";
import "../extensions/IPlanets.sol";
import "../extensions/IFleets.sol";

contract Plundering is IPlundering, SanctisModule {
    /* ========== Sanctis extensions used ========== */
    bytes32 constant COMMANDERS = "COMMANDERS";
    bytes32 constant PLANETS = "PLANETS";
    bytes32 constant FLEETS = "FLEETS";

    /* ========== Contract variables ========== */
    uint8 constant PLANET_STATUS_UNKNOWN = 0;
    uint8 constant PLANET_STATUS_UNCHARTED = 1;
    uint8 constant PLANET_STATUS_COLONIZED = 2;
    uint8 constant PLANET_STATUS_SANCTIS = 3;

    uint256 constant FLEET_STATUS_PREPARING = 0;
    uint256 constant FLEET_STATUS_ORBITING = 1;
    uint256 constant FLEET_STATUS_TRAVELLING = 2;
    uint256 constant FLEET_STATUS_DESTROYED = 3;

    mapping(uint256 => uint256) internal _lastPlundering;
    uint256 internal _plunderPeriod;
    uint256 internal _plunderRate;

    constructor(
        ISanctis newSanctis,
        uint256 plunderPeriod_,
        uint256 plunderRate_
    ) SanctisModule(newSanctis) {
        _plunderPeriod = plunderPeriod_;
        _plunderRate = plunderRate_;
    }

    /* ========== Fleets interfaces ========== */
    function plunder(uint256 fleetId, IResource resource) external {
        IFleets.Fleet memory targetFleet = IFleets(s_sanctis.extension(FLEETS))
            .fleet(fleetId);

        _assertApprovedCommander(targetFleet.commander, msg.sender);
        if (targetFleet.status != FLEET_STATUS_ORBITING)
            revert IFleets.InvalidFleetStatus({
                fleetId: fleetId,
                status: targetFleet.status
            });

        IPlanets.Planet memory targetPlanet = IPlanets(
            s_sanctis.extension(PLANETS)
        ).planet(targetFleet.fromPlanetId);
        if (targetPlanet.status != PLANET_STATUS_COLONIZED)
            revert IPlanets.InvalidPlanet({planet: targetFleet.fromPlanetId});
        if (
            _lastPlundering[targetFleet.fromPlanetId] + _plunderPeriod >
            block.number
        ) revert PlunderingTooEarly({planetId: targetFleet.fromPlanetId});

        (, uint256 planetDefensivePower) = IFleets(s_sanctis.extension(FLEETS))
            .planet(targetFleet.fromPlanetId);
        if (targetFleet.totalOffensivePower <= planetDefensivePower)
            revert FleetTooWeak({fleetId: fleetId});

        _lastPlundering[targetFleet.fromPlanetId] = block.number;
        uint256 plunderAmount = (resource.reserve(targetFleet.fromPlanetId) *
            _plunderRate) / 10000;
        uint256 loadable = plunderAmount >= targetFleet.capacity
            ? targetFleet.capacity
            : plunderAmount;

        IFleets(s_sanctis.extension(FLEETS)).allowedLoad(
            fleetId,
            resource,
            loadable
        );
    }

    function defendPlanet(uint256 planetId, uint256 fleetId) external {
        IFleets.Fleet memory targetFleet = IFleets(s_sanctis.extension(FLEETS))
            .fleet(fleetId);
        (uint256 planetOffensivePower, ) = IFleets(s_sanctis.extension(FLEETS))
            .planet(targetFleet.fromPlanetId);
        _assertApprovedCommander(targetFleet.commander, msg.sender);
        if (planetOffensivePower < targetFleet.totalDefensivePower)
            revert PlanetTooWeak({
                planetId: planetId,
                received: planetOffensivePower,
                required: targetFleet.totalDefensivePower
            });
        if (targetFleet.status != FLEET_STATUS_ORBITING)
            revert IFleets.InvalidFleetStatus({
                fleetId: fleetId,
                status: targetFleet.status
            });

        targetFleet.status = FLEET_STATUS_DESTROYED;
        IFleets(s_sanctis.extension(FLEETS)).setFleet(fleetId, targetFleet);
    }

    function plunderPeriod() external view returns (uint256) {
        return _plunderPeriod;
    }

    function plunderRate() external view returns (uint256) {
        return _plunderRate;
    }

    function nextPlundering(uint256 planetId) external view returns (uint256) {
        return _lastPlundering[planetId] + _plunderPeriod;
    }

    function setParameters(uint256 plunderPeriod_, uint256 plunderRate_)
        external
        onlyExecutor
    {
        _plunderPeriod = plunderPeriod_;
        _plunderRate = plunderRate_;
    }

    /* ========== Assertions ========== */
    /// @notice Asserts that the caller can interact with the commander
    function _assertApprovedCommander(uint256 commanderId, address caller)
        internal
        view
    {
        if (
            !ICommanders(s_sanctis.extension(COMMANDERS)).isApproved(
                caller,
                commanderId
            )
        ) revert IFleets.NotCommanderOwner({commanderId: commanderId});
    }
}
