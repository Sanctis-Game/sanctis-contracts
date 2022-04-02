// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "openzeppelin-contracts/contracts/utils/structs/EnumerableSet.sol";

import "./IFleets.sol";
import "./IPlanets.sol";
import "./ICommanders.sol";
import "../ships/IShip.sol";
import "../SanctisExtension.sol";

contract Fleets is IFleets, SanctisExtension {
    using EnumerableSet for EnumerableSet.UintSet;

    /* ========== Sanctis extensions used ========== */
    bytes32 constant COMMANDERS = bytes32("COMMANDERS");
    bytes32 constant PLANETS = bytes32("PLANETS");
    bytes32 constant FLEETS = bytes32("FLEETS");

    /* ========== Contract variables ========== */
    uint8 constant PLANET_STATUS_UNKNOWN = 0;
    uint8 constant PLANET_STATUS_UNCHARTED = 1;
    uint8 constant PLANET_STATUS_COLONIZED = 2;
    uint8 constant PLANET_STATUS_SANCTIS = 3;

    uint256 constant FLEET_STATUS_PREPARING = 0;
    uint256 constant FLEET_STATUS_ORBITING = 1;
    uint256 constant FLEET_STATUS_TRAVELLING = 2;
    uint256 constant FLEET_STATUS_DESTROYED = 3;

    mapping(uint256 => Fleet) internal _fleets;
    mapping(uint256 => EnumerableSet.UintSet) internal _fleetsOnPlanet;
    mapping(uint256 => uint256) internal _planetOffensivePower;
    mapping(uint256 => uint256) internal _planetDefensivePower;
    mapping(IResource => mapping(uint256 => uint256)) internal _stockPerFleet;
    mapping(address => mapping(uint256 => uint256)) internal _shipsPerFleet;

    constructor(ISanctis newSanctis) SanctisExtension(FLEETS, newSanctis) {}

    /* ========== Fleets interfaces ========== */
    function fleet(uint256 fleetId) external view returns (Fleet memory) {
        return _fleets[fleetId];
    }

    function planet(uint256 planetId) external view returns (uint256, uint256) {
        return (
            _planetOffensivePower[planetId],
            _planetDefensivePower[planetId]
        );
    }

    function shipsInFleet(IShip ship, uint256 fleetId)
        external
        view
        returns (uint256)
    {
        return _shipsPerFleet[address(ship)][fleetId];
    }

    function fleetsOnPlanet(uint256 planetId) external view returns (uint256) {
        return _fleetsOnPlanet[planetId].length();
    }

    function fleetOnPlanetByIndex(uint256 planetId, uint256 index)
        external
        view
        returns (uint256)
    {
        return _fleetsOnPlanet[planetId].at(index);
    }

    function resourceInFleet(IResource resource, uint256 fleetId)
        external
        view
        returns (uint256)
    {
        return _stockPerFleet[resource][fleetId];
    }

    function createFleet(
        uint256 fleetId,
        uint256 commanderId,
        uint256 planetId
    ) public {
        Fleet memory targetFleet = _fleets[fleetId];

        if (targetFleet.commander != 0)
            revert AlreadyExists({fleetId: fleetId});

        if (
            IPlanets(s_sanctis.extension(PLANETS)).planet(planetId).ruler !=
            commanderId
        ) revert NotRuler({commanderId: commanderId, planetId: planetId});

        targetFleet.commander = commanderId;
        targetFleet.fromPlanetId = planetId;
        targetFleet.toPlanetId = planetId;
        targetFleet.totalSpeed = 0;
        targetFleet.totalOffensivePower = 0;
        targetFleet.totalDefensivePower = 0;
        targetFleet.capacity = 0;
        targetFleet.ships = 0;
        targetFleet.arrivalBlock = 0;
        targetFleet.status = FLEET_STATUS_PREPARING;
        _fleets[fleetId] = targetFleet;
        _fleetsOnPlanet[planetId].add(fleetId);
    }

    function addToFleet(
        uint256 fleetId,
        IShip ship,
        uint256 amount
    ) public {
        Fleet memory targetFleet = _fleets[fleetId];

        _assertApprovedCommander(_fleets[fleetId].commander, msg.sender);
        _assertIsOnRuledPlanet(fleetId);
        if (targetFleet.status != FLEET_STATUS_PREPARING)
            revert InvalidFleetStatus({
                fleetId: fleetId,
                status: targetFleet.status
            });

        targetFleet.totalSpeed += amount * ship.speed();
        targetFleet.totalOffensivePower += amount * ship.offensivePower();
        _planetOffensivePower[targetFleet.fromPlanetId] +=
            amount *
            ship.offensivePower();
        targetFleet.totalDefensivePower += amount * ship.defensivePower();
        _planetDefensivePower[targetFleet.fromPlanetId] +=
            amount *
            ship.defensivePower();
        targetFleet.capacity += amount * ship.capacity();
        targetFleet.ships += amount;
        _fleets[fleetId] = targetFleet;

        _shipsPerFleet[address(ship)][fleetId] += amount;
        ship.burn(targetFleet.fromPlanetId, amount);
    }

    function removeFromFleet(
        uint256 fleetId,
        IShip ship,
        uint256 amount
    ) public {
        Fleet memory targetFleet = _fleets[fleetId];

        _assertApprovedCommander(_fleets[fleetId].commander, msg.sender);
        _assertIsOnRuledPlanet(fleetId);
        if (targetFleet.status != FLEET_STATUS_PREPARING)
            revert InvalidFleetStatus({
                fleetId: fleetId,
                status: targetFleet.status
            });

        targetFleet.totalSpeed -= amount * ship.speed();
        targetFleet.totalOffensivePower -= amount * ship.offensivePower();
        _planetOffensivePower[targetFleet.fromPlanetId] -=
            amount *
            ship.offensivePower();
        targetFleet.totalDefensivePower -= amount * ship.defensivePower();
        _planetDefensivePower[targetFleet.fromPlanetId] -=
            amount *
            ship.defensivePower();
        targetFleet.capacity -= amount * ship.capacity();
        targetFleet.ships -= amount;
        _fleets[fleetId] = targetFleet;

        _shipsPerFleet[address(ship)][fleetId] -= amount;
        ship.mint(targetFleet.fromPlanetId, amount);
    }

    function putInOrbit(uint256 fleetId) external {
        Fleet memory targetFleet = _fleets[fleetId];

        _assertApprovedCommander(_fleets[fleetId].commander, msg.sender);
        _assertIsOnRuledPlanet(fleetId);
        if (targetFleet.status != FLEET_STATUS_PREPARING)
            revert InvalidFleetStatus({
                fleetId: fleetId,
                status: targetFleet.status
            });
        if (targetFleet.ships == 0) revert EmptyFleet({fleetId: fleetId});

        targetFleet.status = FLEET_STATUS_ORBITING;
        _fleets[fleetId] = targetFleet;
        _planetOffensivePower[targetFleet.fromPlanetId] -= targetFleet
            .totalOffensivePower;
        _planetDefensivePower[targetFleet.fromPlanetId] -= targetFleet
            .totalDefensivePower;
    }

    function land(uint256 fleetId) external {
        Fleet memory targetFleet = _fleets[fleetId];

        _assertApprovedCommander(_fleets[fleetId].commander, msg.sender);
        _assertIsOnRuledPlanet(fleetId);
        if (targetFleet.status != FLEET_STATUS_ORBITING)
            revert InvalidFleetStatus({
                fleetId: fleetId,
                status: targetFleet.status
            });

        targetFleet.status = FLEET_STATUS_PREPARING;
        _fleets[fleetId] = targetFleet;
        _planetOffensivePower[targetFleet.fromPlanetId] += targetFleet
            .totalOffensivePower;
        _planetDefensivePower[targetFleet.fromPlanetId] += targetFleet
            .totalDefensivePower;
    }

    function moveFleet(uint256 fleetId, uint256 toPlanetId) external {
        Fleet memory targetFleet = _fleets[fleetId];

        _assertApprovedCommander(_fleets[fleetId].commander, msg.sender);
        if (targetFleet.status != FLEET_STATUS_ORBITING)
            revert InvalidFleetStatus({
                fleetId: fleetId,
                status: targetFleet.status
            });

        IPlanets.Planet memory targetPlanet = IPlanets(
            s_sanctis.extension(PLANETS)
        ).planet(toPlanetId);
        if (targetPlanet.status == PLANET_STATUS_UNKNOWN)
            revert IPlanets.InvalidPlanet({planet: toPlanetId});

        targetFleet.status = FLEET_STATUS_TRAVELLING;
        targetFleet.toPlanetId = toPlanetId;
        targetFleet.arrivalBlock =
            block.number +
            IPlanets(s_sanctis.extension(PLANETS)).distance(
                targetFleet.fromPlanetId,
                toPlanetId
            ) /
            (targetFleet.totalSpeed / targetFleet.ships);

        _fleets[fleetId] = targetFleet;
        _fleetsOnPlanet[targetFleet.fromPlanetId].remove(fleetId);
    }

    function settleFleet(uint256 fleetId) external {
        Fleet memory targetFleet = _fleets[fleetId];

        if (
            targetFleet.status != FLEET_STATUS_TRAVELLING &&
            targetFleet.arrivalBlock > block.number
        ) revert NotArrivedYet({fleetId: fleetId});

        targetFleet.status = FLEET_STATUS_ORBITING;
        targetFleet.fromPlanetId = targetFleet.toPlanetId;

        _fleets[fleetId] = targetFleet;
        _fleetsOnPlanet[targetFleet.fromPlanetId].add(fleetId);
    }

    function load(
        uint256 fleetId,
        IResource resource,
        uint256 amount
    ) external {
        _assertApprovedCommander(_fleets[fleetId].commander, msg.sender);
        _assertIsOnRuledPlanet(fleetId);
        if (
            _fleets[fleetId].status != FLEET_STATUS_PREPARING &&
            _fleets[fleetId].status != FLEET_STATUS_ORBITING
        )
            revert InvalidFleetStatus({
                fleetId: fleetId,
                status: _fleets[fleetId].status
            });

        _fleets[fleetId].capacity -= amount;
        _stockPerFleet[resource][fleetId] += amount;
        resource.burn(_fleets[fleetId].fromPlanetId, amount);
    }

    function unload(
        uint256 fleetId,
        IResource resource,
        uint256 amount
    ) external {
        _assertApprovedCommander(_fleets[fleetId].commander, msg.sender);
        if (
            _fleets[fleetId].status != FLEET_STATUS_PREPARING &&
            _fleets[fleetId].status != FLEET_STATUS_ORBITING
        )
            revert InvalidFleetStatus({
                fleetId: fleetId,
                status: _fleets[fleetId].status
            });

        _fleets[fleetId].capacity += amount;
        _stockPerFleet[resource][fleetId] -= amount;
        resource.mint(_fleets[fleetId].fromPlanetId, amount);
    }

    function allowedLoad(
        uint256 fleetId,
        IResource resource,
        uint256 amount
    ) external onlyAllowed {
        _fleets[fleetId].capacity -= amount;
        _stockPerFleet[resource][fleetId] += amount;
        resource.burn(_fleets[fleetId].fromPlanetId, amount);
    }

    function allowedUnload(
        uint256 fleetId,
        IResource resource,
        uint256 amount
    ) external onlyAllowed {
        _fleets[fleetId].capacity += amount;
        _stockPerFleet[resource][fleetId] -= amount;
        resource.mint(_fleets[fleetId].fromPlanetId, amount);
    }

    function setFleet(uint256 fleetId, Fleet memory newFleet)
        external
        onlyAllowed
    {
        _fleets[fleetId] = newFleet;
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
        ) revert NotCommanderOwner({commanderId: commanderId});
    }

    /// @notice Asserts that the planet the fleet is on is controlled by the fleet controller
    function _assertIsOnRuledPlanet(uint256 fleetId) internal view {
        if (
            IPlanets(s_sanctis.extension(PLANETS))
                .planet(_fleets[fleetId].fromPlanetId)
                .ruler != _fleets[fleetId].commander
        )
            revert NotRuler({
                commanderId: _fleets[fleetId].commander,
                planetId: _fleets[fleetId].fromPlanetId
            });
    }
}
