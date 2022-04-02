// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "../ISanctisExtension.sol";
import "../ships/IShip.sol";

interface IFleets is ISanctisExtension {
    error NotCommanderOwner(uint256 commanderId);
    error NotRuler(uint256 commanderId, uint256 planetId);
    error InvalidFleetStatus(uint256 fleetId, uint256 status);
    error NotEnoughCapacity(uint256 fleetId, uint256 capacity);
    error AlreadyExists(uint256 fleetId);
    error AlreadyMoving(uint256 fleetId);
    error EmptyFleet(uint256 fleetId);
    error NotArrivedYet(uint256 fleetId);

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
        uint256 status;
    }

    function fleet(uint256 fleetId) external view returns (Fleet memory);

    function planet(uint256 planetId) external view returns (uint256, uint256);

    function shipsInFleet(IShip ship, uint256 fleetId)
        external
        view
        returns (uint256);

    function fleetsOnPlanet(uint256 planetId) external view returns (uint256);

    function fleetOnPlanetByIndex(uint256 planetId, uint256 index)
        external
        view
        returns (uint256);

    function resourceInFleet(IResource resource, uint256 fleetId)
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

    function putInOrbit(uint256 fleetId) external;

    function land(uint256 fleetId) external;

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

    function allowedLoad(
        uint256 fleetId,
        IResource resource,
        uint256 amount
    ) external;

    function allowedUnload(
        uint256 fleetId,
        IResource resource,
        uint256 amount
    ) external;

    function setFleet(uint256 fleetId, Fleet memory newFleet) external;
}
