// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./ISanctis.sol";
import "./IShip.sol";

interface IFleets {
    error NotCommanderOwner(uint256 commanderId);
    error NotRuler(uint256 commanderId, uint256 planetId);
    error InvalidFleetStatus(uint256 fleetId, FleetStatus status);
    error NotEnoughCapacity(uint256 fleetId, uint256 capacity);
    error PlunderingTooEarly(uint256 planetId);
    error FleetTooWeak(uint256 fleetId);
    error PlanetTooWeak(uint256 planetId, uint256 received, uint256 required);
    error AlreadyExists(uint256 fleetId);
    error AlreadyMoving(uint256 fleetId);
    error EmptyFleet(uint256 fleetId);
    error NotArrivedYet(uint256 fleetId);

    enum FleetStatus {
        Preparing,
        Orbiting,
        Travelling,
        Destroyed
    }

    struct Fleet {
        uint256 commander;
        uint256 fromPlanetId;
        uint256 toPlanetId;
        uint256 totalSpeed;
        uint256 totalOffensivePower;
        uint256 totalDefensivePower;
        uint256 capacity;
        uint256 ships;
        uint256 arrivalBlock;
        FleetStatus status;
    }

    function fleet(uint256 fleetId) external view returns (Fleet memory);

    function shipsInFleet(IShip ship, uint256 fleetId)
        external
        view
        returns (uint256);

    function createFleet(
        uint256 fleetId,
        uint256 commanderId,
        uint256 planetId
    ) external;

    function addToFleet(
        uint256 fleetId,
        IShip ship,
        uint256 amount
    ) external;

    function removeFromFleet(
        uint256 fleetId,
        IShip ship,
        uint256 amount
    ) external;

    function moveFleet(uint256 fleetId, uint256 toPlanetId) external;

    function settleFleet(uint256 fleetId) external;

    function load(
        uint256 fleetId,
        IResource resource,
        uint256 amount
    ) external;

    function unload(
        uint256 fleetId,
        IResource resource,
        uint256 amount
    ) external;

    function plunder(uint256 fleetId, IResource resource) external;

    function defendPlanet(uint256 planetId, uint256 fleetId) external;

    function plunderPeriod() external view returns (uint256);

    function plunderRate() external view returns (uint256);

    function nextPlundering(uint256 planetId) external view returns (uint256);

    function setFleet(uint256 fleetId, Fleet memory newFleet) external;
}
