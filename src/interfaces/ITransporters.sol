// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./Cost.sol";
import "./IShip.sol";
import "./IResource.sol";

interface ITransporters is IShip {
    error NotEnoughCapacity(uint256 maxCapacity);

    struct Transporter {
        /// @notice The quantity of resources a transporter can hold
        uint256 capacity;
        /// @notice Speed of the transporter in unit per block
        uint256 speed;
        /// @notice Resources needed to build the transporter
        Cost[] costs;
    }

    function addToFleet(
        uint256 fleetId,
        uint256 ships,
        IResource resource,
        uint256 quantity
    ) external;

    function characteristics() external view returns (Transporter memory);
}
