// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./Cost.sol";
import "./IShip.sol";

interface ITransporters is IShip {
    struct Transporter {
        /// @notice The quantity of resources a transporter can hold
        uint256 capacity;
        /// @notice Speed of the transporter in unit per block
        uint256 speed;
        /// @notice Resources needed to build the transporter
        Cost[] costs;
    }

    function transport(
        uint256 fromPlanetId,
        uint256 toPlanetId,
        uint256 amount,
        uint256 ships
    ) external;

    function characteristics() external view returns (Transporter memory);
}
