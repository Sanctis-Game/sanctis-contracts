// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./ISanctis.sol";
import "./IShip.sol";

interface IFleets {
    error NotCommanderOwner(uint256 commanderId);
    error AlreadyExists(uint256 fleetId);
    error AlreadyMoving(uint256 fleetId);

    enum FleetStatus {
        Preparing,
        Travelling,
        Arrived
    }

    struct Fleet {
        uint256 commander;
        uint256 fromPlanetId;
        uint256 toPlanetId;
        uint256 speed;
        uint256 arrivalBlock;
        FleetStatus status;
    }

    function fleet(uint256 fleetId) external view returns (Fleet memory);

    function createFleet(uint256 fleetId, uint256 commanderId, uint256 planetId) external;

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

    function moveFleet(uint256 fromPlanetId, uint256 toPlanetId) external;
}
