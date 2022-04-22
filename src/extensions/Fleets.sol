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
    uint8 constant PLANET_STATUS_SANCTIS = 2;
    uint8 constant PLANET_STATUS_COLONIZED = 3;

    uint256 constant FLEET_STATUS_PREPARING = 0;
    uint256 constant FLEET_STATUS_ORBITING = 1;
    uint256 constant FLEET_STATUS_TRAVELLING = 2;
    uint256 constant FLEET_STATUS_DESTROYED = 3;

    uint256 internal s_createdFleets;
    mapping(uint256 => Fleet) internal s_fleets;
    mapping(uint256 => EnumerableSet.UintSet) internal s_fleetsOnPlanet;
    mapping(uint256 => uint256) internal s_planetOffensivePower;
    mapping(uint256 => uint256) internal s_planetDefensivePower;
    mapping(IResource => mapping(uint256 => uint256)) internal s_stockPerFleet;
    mapping(address => mapping(uint256 => uint256)) internal s_shipsPerFleet;

    constructor(ISanctis newSanctis) SanctisExtension(FLEETS, newSanctis) {}

    /* ========== Fleets interfaces ========== */
    function fleet(uint256 fleetId) external view returns (Fleet memory) {
        return s_fleets[fleetId];
    }

    function planet(uint256 planetId) external view returns (uint256, uint256) {
        return (
            s_planetOffensivePower[planetId],
            s_planetDefensivePower[planetId]
        );
    }

    function shipsInFleet(IShip ship, uint256 fleetId)
        external
        view
        returns (uint256)
    {
        return s_shipsPerFleet[address(ship)][fleetId];
    }

    function fleetsOnPlanet(uint256 planetId) external view returns (uint256) {
        return s_fleetsOnPlanet[planetId].length();
    }

    function fleetOnPlanetByIndex(uint256 planetId, uint256 index)
        external
        view
        returns (uint256)
    {
        return s_fleetsOnPlanet[planetId].at(index);
    }

    function resourceInFleet(IResource resource, uint256 fleetId)
        external
        view
        returns (uint256)
    {
        return s_stockPerFleet[resource][fleetId];
    }

    function createFleet(uint256 commanderId, uint256 planetId) public {
        uint256 fleetId = s_createdFleets++;
        Fleet memory targetFleet = s_fleets[fleetId];

        require(targetFleet.commander == 0, "Fleets: Exists");
        require(
            IPlanets(s_sanctis.extension(PLANETS)).planet(planetId).ruler ==
                commanderId,
            "Fleets: Planet ruler"
        );

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
        s_fleets[fleetId] = targetFleet;
        s_fleetsOnPlanet[planetId].add(fleetId);

        emit Moved({
            fleet: fleetId,
            from: targetFleet.fromPlanetId,
            to: targetFleet.toPlanetId,
            status: FLEET_STATUS_PREPARING
        });
    }

    function addToFleet(
        uint256 fleetId,
        IShip ship,
        uint256 amount
    ) public {
        Fleet memory targetFleet = s_fleets[fleetId];

        _assertApprovedCommander(s_fleets[fleetId].commander, msg.sender);
        _assertIsOnRuledPlanet(fleetId);
        require(targetFleet.status == FLEET_STATUS_PREPARING, "Fleets: Status");

        targetFleet.totalSpeed += amount * ship.speed();
        targetFleet.totalOffensivePower += amount * ship.offensivePower();
        s_planetOffensivePower[targetFleet.fromPlanetId] +=
            amount *
            ship.offensivePower();
        targetFleet.totalDefensivePower += amount * ship.defensivePower();
        s_planetDefensivePower[targetFleet.fromPlanetId] +=
            amount *
            ship.defensivePower();
        targetFleet.capacity += amount * ship.capacity();
        targetFleet.ships += amount;
        s_fleets[fleetId] = targetFleet;

        s_shipsPerFleet[address(ship)][fleetId] += amount;
        ship.burn(targetFleet.fromPlanetId, amount);
    }

    function removeFromFleet(
        uint256 fleetId,
        IShip ship,
        uint256 amount
    ) public {
        Fleet memory targetFleet = s_fleets[fleetId];

        _assertApprovedCommander(s_fleets[fleetId].commander, msg.sender);
        _assertIsOnRuledPlanet(fleetId);
        require(targetFleet.status == FLEET_STATUS_PREPARING, "Fleets: Status");

        targetFleet.totalSpeed -= amount * ship.speed();
        targetFleet.totalOffensivePower -= amount * ship.offensivePower();
        s_planetOffensivePower[targetFleet.fromPlanetId] -=
            amount *
            ship.offensivePower();
        targetFleet.totalDefensivePower -= amount * ship.defensivePower();
        s_planetDefensivePower[targetFleet.fromPlanetId] -=
            amount *
            ship.defensivePower();
        targetFleet.capacity -= amount * ship.capacity();
        targetFleet.ships -= amount;
        s_fleets[fleetId] = targetFleet;

        s_shipsPerFleet[address(ship)][fleetId] -= amount;
        ship.mint(targetFleet.fromPlanetId, amount);
    }

    function putInOrbit(uint256 fleetId) external {
        Fleet memory targetFleet = s_fleets[fleetId];

        _assertApprovedCommander(s_fleets[fleetId].commander, msg.sender);
        _assertIsOnRuledPlanet(fleetId);
        require(targetFleet.status == FLEET_STATUS_PREPARING, "Fleets: Status");
        require(targetFleet.ships > 0, "Fleets: Empty fleet");

        targetFleet.status = FLEET_STATUS_ORBITING;
        s_fleets[fleetId] = targetFleet;
        s_planetOffensivePower[targetFleet.fromPlanetId] -= targetFleet
            .totalOffensivePower;
        s_planetDefensivePower[targetFleet.fromPlanetId] -= targetFleet
            .totalDefensivePower;

        emit Moved({
            fleet: fleetId,
            from: targetFleet.fromPlanetId,
            to: targetFleet.toPlanetId,
            status: FLEET_STATUS_ORBITING
        });
    }

    function land(uint256 fleetId) external {
        Fleet memory targetFleet = s_fleets[fleetId];

        _assertApprovedCommander(s_fleets[fleetId].commander, msg.sender);
        _assertIsOnRuledPlanet(fleetId);
        require(targetFleet.status == FLEET_STATUS_ORBITING, "Fleets: Status");

        targetFleet.status = FLEET_STATUS_PREPARING;
        s_fleets[fleetId] = targetFleet;
        s_planetOffensivePower[targetFleet.fromPlanetId] += targetFleet
            .totalOffensivePower;
        s_planetDefensivePower[targetFleet.fromPlanetId] += targetFleet
            .totalDefensivePower;

        emit Moved({
            fleet: fleetId,
            from: targetFleet.fromPlanetId,
            to: targetFleet.toPlanetId,
            status: FLEET_STATUS_PREPARING
        });
    }

    function moveFleet(uint256 fleetId, uint256 toPlanetId) external {
        Fleet memory targetFleet = s_fleets[fleetId];

        _assertApprovedCommander(s_fleets[fleetId].commander, msg.sender);
        require(targetFleet.status == FLEET_STATUS_ORBITING, "Fleets: Status");

        IPlanets.Planet memory targetPlanet = IPlanets(
            s_sanctis.extension(PLANETS)
        ).planet(toPlanetId);
        require(targetPlanet.status != PLANET_STATUS_UNKNOWN, "Fleets: Planet");

        targetFleet.status = FLEET_STATUS_TRAVELLING;
        targetFleet.toPlanetId = toPlanetId;
        targetFleet.arrivalBlock =
            block.number +
            IPlanets(s_sanctis.extension(PLANETS)).distance(
                targetFleet.fromPlanetId,
                toPlanetId
            ) /
            (targetFleet.totalSpeed / targetFleet.ships);

        s_fleets[fleetId] = targetFleet;
        s_fleetsOnPlanet[targetFleet.fromPlanetId].remove(fleetId);

        emit Moved({
            fleet: fleetId,
            from: targetFleet.fromPlanetId,
            to: targetFleet.toPlanetId,
            status: FLEET_STATUS_TRAVELLING
        });
    }

    function settleFleet(uint256 fleetId) external {
        Fleet memory targetFleet = s_fleets[fleetId];

        require(
            targetFleet.status == FLEET_STATUS_TRAVELLING &&
                targetFleet.arrivalBlock <= block.number,
            "Fleets: Not arrived"
        );

        targetFleet.status = FLEET_STATUS_ORBITING;
        targetFleet.fromPlanetId = targetFleet.toPlanetId;

        s_fleets[fleetId] = targetFleet;
        s_fleetsOnPlanet[targetFleet.fromPlanetId].add(fleetId);

        emit Moved({
            fleet: fleetId,
            from: targetFleet.fromPlanetId,
            to: targetFleet.toPlanetId,
            status: FLEET_STATUS_ORBITING
        });
    }

    function load(
        uint256 fleetId,
        IResource resource,
        uint256 amount
    ) external {
        _assertApprovedCommander(s_fleets[fleetId].commander, msg.sender);
        _assertIsOnRuledPlanet(fleetId);
        require(
            s_fleets[fleetId].status == FLEET_STATUS_PREPARING ||
                s_fleets[fleetId].status == FLEET_STATUS_ORBITING,
            "Fleets: Status"
        );

        s_fleets[fleetId].capacity -= amount;
        s_stockPerFleet[resource][fleetId] += amount;
        resource.burn(s_fleets[fleetId].fromPlanetId, amount);
    }

    function unload(
        uint256 fleetId,
        IResource resource,
        uint256 amount
    ) external {
        _assertApprovedCommander(s_fleets[fleetId].commander, msg.sender);
        require(
            s_fleets[fleetId].status == FLEET_STATUS_PREPARING ||
                s_fleets[fleetId].status == FLEET_STATUS_ORBITING,
            "Fleets: Status"
        );

        s_fleets[fleetId].capacity += amount;
        s_stockPerFleet[resource][fleetId] -= amount;
        resource.mint(s_fleets[fleetId].fromPlanetId, amount);
    }

    function allowedLoad(
        uint256 fleetId,
        IResource resource,
        uint256 amount
    ) external onlyAllowed {
        s_fleets[fleetId].capacity -= amount;
        s_stockPerFleet[resource][fleetId] += amount;
        resource.burn(s_fleets[fleetId].fromPlanetId, amount);
    }

    function allowedUnload(
        uint256 fleetId,
        IResource resource,
        uint256 amount
    ) external onlyAllowed {
        s_fleets[fleetId].capacity += amount;
        s_stockPerFleet[resource][fleetId] -= amount;
        resource.mint(s_fleets[fleetId].fromPlanetId, amount);
    }

    function setFleet(uint256 fleetId, Fleet memory newFleet)
        external
        onlyAllowed
    {
        s_fleets[fleetId] = newFleet;
    }

    /* ========== Assertions ========== */
    /// @notice Asserts that the caller can interact with the commander
    function _assertApprovedCommander(uint256 commanderId, address caller)
        internal
        view
    {
        require(
            ICommanders(s_sanctis.extension(COMMANDERS)).isApproved(
                caller,
                commanderId
            ),
            "Fleets: Commander"
        );
    }

    /// @notice Asserts that the planet the fleet is on is controlled by the fleet controller
    function _assertIsOnRuledPlanet(uint256 fleetId) internal view {
        require(
            IPlanets(s_sanctis.extension(PLANETS))
                .planet(s_fleets[fleetId].fromPlanetId)
                .ruler == s_fleets[fleetId].commander,
            "Fleets: Approved"
        );
    }
}
