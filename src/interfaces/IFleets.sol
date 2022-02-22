// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "./ISanctis.sol";

interface IFleets {
    enum FleetStatus {
        Preparing,
        Travelling,
        Arrived
    }

    struct Fleet {
        uint256 id;
        uint256 fromPlanetId;
        uint256 toPlanetId;
        uint256 arrivalBlock;
        FleetStatus status;
    }

    function fleet(uint256 fleetId) external view returns (Fleet memory);

    function moveFleet(
        uint256 fromPlanetId,
        uint256 toPlanetId
    ) external;
}
