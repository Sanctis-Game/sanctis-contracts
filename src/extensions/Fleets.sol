// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "openzeppelin-contracts/contracts/utils/introspection/IERC165.sol";
import "openzeppelin-contracts/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

import "../interfaces/ISanctis.sol";
import "../interfaces/ICommanders.sol";
import "../interfaces/IPlanets.sol";
import "../interfaces/IFleets.sol";
import "../interfaces/IShip.sol";
import "../SanctisExtension.sol";

contract Fleets is IFleets, SanctisExtension {
    /* ========== Sanctis extensions used ========== */
    string constant COMMANDERS = "COMMANDERS";
    string constant PLANETS = "PLANETS";

    /* ========== Contract variables ========== */
    mapping(uint256 => Fleet) internal _fleets;
    mapping(uint256 => uint256) internal _planetOffensivePower;
    mapping(uint256 => uint256) internal _planetDefensivePower;
    mapping(IResource => mapping(uint256 => uint256)) internal _stockPerFleet;
    mapping(address => mapping(uint256 => uint256)) internal _shipsPerFleet;
    mapping(uint256 => uint256) internal _lastPlundering;
    uint256 internal _plunderPeriod;
    uint256 internal _plunderRate;

    constructor(
        ISanctis newSanctis,
        uint256 plunderPeriod_,
        uint256 plunderRate_
    ) SanctisExtension("FLEETS", newSanctis) {
        _plunderPeriod = plunderPeriod_;
        _plunderRate = plunderRate_;
    }

    /* ========== Fleets interfaces ========== */
    function fleet(uint256 fleetId) external view returns (Fleet memory) {
        return _fleets[fleetId];
    }

    function shipsInFleet(IShip ship, uint256 fleetId)
        external
        view
        returns (uint256)
    {
        return _shipsPerFleet[address(ship)][fleetId];
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
            IPlanets(sanctis.extension(PLANETS)).planet(planetId).ruler !=
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
        targetFleet.status = FleetStatus.Preparing;
        _fleets[fleetId] = targetFleet;
    }

    function addToFleet(
        uint256 fleetId,
        IShip ship,
        uint256 amount
    ) public {
        Fleet memory targetFleet = _fleets[fleetId];

        _assertApprovedCommander(_fleets[fleetId].commander, msg.sender);
        _assertIsOnRuledPlanet(fleetId);
        if (targetFleet.status != FleetStatus.Preparing)
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
        if (targetFleet.status != FleetStatus.Preparing)
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
        if (targetFleet.status != FleetStatus.Preparing)
            revert InvalidFleetStatus({
                fleetId: fleetId,
                status: targetFleet.status
            });
        if (targetFleet.ships == 0) revert EmptyFleet({fleetId: fleetId});

        targetFleet.status = FleetStatus.Orbiting;
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
        if (targetFleet.status != FleetStatus.Orbiting)
            revert InvalidFleetStatus({
                fleetId: fleetId,
                status: targetFleet.status
            });

        targetFleet.status = FleetStatus.Preparing;
        _fleets[fleetId] = targetFleet;
        _planetOffensivePower[targetFleet.fromPlanetId] += targetFleet
            .totalOffensivePower;
        _planetDefensivePower[targetFleet.fromPlanetId] += targetFleet
            .totalDefensivePower;
    }

    function moveFleet(uint256 fleetId, uint256 toPlanetId) external {
        Fleet memory targetFleet = _fleets[fleetId];

        _assertApprovedCommander(_fleets[fleetId].commander, msg.sender);
        if (targetFleet.status != FleetStatus.Orbiting)
            revert InvalidFleetStatus({
                fleetId: fleetId,
                status: targetFleet.status
            });

        IPlanets.Planet memory targetPlanet = IPlanets(
            sanctis.extension(PLANETS)
        ).planet(toPlanetId);
        if (targetPlanet.status == IPlanets.PlanetStatus.Unknown)
            revert IPlanets.InvalidPlanet({planet: toPlanetId});

        targetFleet.status = FleetStatus.Travelling;
        targetFleet.toPlanetId = toPlanetId;
        targetFleet.arrivalBlock =
            block.number +
            IPlanets(sanctis.extension(PLANETS)).distance(
                targetFleet.fromPlanetId,
                toPlanetId
            ) /
            (targetFleet.totalSpeed / targetFleet.ships);

        _fleets[fleetId] = targetFleet;
    }

    function settleFleet(uint256 fleetId) external {
        Fleet memory targetFleet = _fleets[fleetId];

        if (
            targetFleet.status != FleetStatus.Travelling &&
            targetFleet.arrivalBlock > block.number
        ) revert NotArrivedYet({fleetId: fleetId});

        targetFleet.status = FleetStatus.Orbiting;
        targetFleet.fromPlanetId = targetFleet.toPlanetId;

        _fleets[fleetId] = targetFleet;
    }

    function load(
        uint256 fleetId,
        IResource resource,
        uint256 amount
    ) external {
        _assertApprovedCommander(_fleets[fleetId].commander, msg.sender);
        _assertIsOnRuledPlanet(fleetId);
        if (
            _fleets[fleetId].status != FleetStatus.Preparing &&
            _fleets[fleetId].status != FleetStatus.Orbiting
        )
            revert InvalidFleetStatus({
                fleetId: fleetId,
                status: _fleets[fleetId].status
            });
        if (_fleets[fleetId].capacity < amount)
            revert NotEnoughCapacity({
                fleetId: fleetId,
                capacity: _fleets[fleetId].capacity
            });

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
            _fleets[fleetId].status != FleetStatus.Preparing &&
            _fleets[fleetId].status != FleetStatus.Orbiting
        )
            revert InvalidFleetStatus({
                fleetId: fleetId,
                status: _fleets[fleetId].status
            });
        if (_stockPerFleet[resource][fleetId] < amount)
            revert NotEnoughCapacity({
                fleetId: fleetId,
                capacity: _stockPerFleet[resource][fleetId]
            });

        _stockPerFleet[resource][fleetId] -= amount;
        resource.mint(_fleets[fleetId].fromPlanetId, amount);
    }

    function plunder(uint256 fleetId, IResource resource) external {
        Fleet memory targetFleet = _fleets[fleetId];

        _assertApprovedCommander(_fleets[fleetId].commander, msg.sender);
        if (targetFleet.status != FleetStatus.Orbiting)
            revert InvalidFleetStatus({
                fleetId: fleetId,
                status: targetFleet.status
            });

        IPlanets.Planet memory targetPlanet = IPlanets(
            sanctis.extension(PLANETS)
        ).planet(targetFleet.fromPlanetId);
        if (targetPlanet.status != IPlanets.PlanetStatus.Colonized)
            revert IPlanets.InvalidPlanet({planet: targetFleet.fromPlanetId});
        if (
            _lastPlundering[targetFleet.fromPlanetId] + _plunderPeriod >
            block.number
        ) revert PlunderingTooEarly({planetId: targetFleet.fromPlanetId});
        if (
            targetFleet.totalOffensivePower <=
            _planetOffensivePower[targetFleet.fromPlanetId]
        ) revert FleetTooWeak({fleetId: fleetId});

        _lastPlundering[targetFleet.fromPlanetId] = block.number;
        uint256 plunderAmount = (resource.reserve(targetFleet.fromPlanetId) *
            _plunderRate) / 10000;
        uint256 loadable = plunderAmount >= targetFleet.capacity
            ? targetFleet.capacity
            : plunderAmount;
        _fleets[fleetId].capacity -= loadable;
        _stockPerFleet[resource][fleetId] += loadable;
        resource.burn(targetFleet.fromPlanetId, plunderAmount);
    }

    function defendPlanet(uint256 planetId, uint256 fleetId) external {
        _assertApprovedCommander(_fleets[fleetId].commander, msg.sender);
        if (
            _planetOffensivePower[planetId] <
            _fleets[fleetId].totalDefensivePower
        )
            revert PlanetTooWeak({
                planetId: planetId,
                received: _planetOffensivePower[planetId],
                required: _fleets[fleetId].totalDefensivePower
            });
        if (_fleets[fleetId].status != FleetStatus.Orbiting)
            revert InvalidFleetStatus({
                fleetId: fleetId,
                status: _fleets[fleetId].status
            });

        _fleets[fleetId].status = FleetStatus.Destroyed;
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

    function setFleet(uint256 fleetId, Fleet memory newFleet)
        external
        onlyAllowed
    {
        _fleets[fleetId] = newFleet;
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
            !ICommanders(sanctis.extension(COMMANDERS)).isApproved(
                caller,
                commanderId
            )
        ) revert NotCommanderOwner({commanderId: commanderId});
    }

    /// @notice Asserts that the planet the fleet is on is controlled by the fleet controller
    function _assertIsOnRuledPlanet(uint256 fleetId) internal view {
        if (
            IPlanets(sanctis.extension(PLANETS))
                .planet(_fleets[fleetId].fromPlanetId)
                .ruler != _fleets[fleetId].commander
        )
            revert NotRuler({
                commanderId: _fleets[fleetId].commander,
                planetId: _fleets[fleetId].fromPlanetId
            });
    }
}
