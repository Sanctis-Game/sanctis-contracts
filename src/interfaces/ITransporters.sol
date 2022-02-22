// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "./IShip.sol";

interface ITransporters is IShip {
    struct Transporter {
        /// @notice The quantity of resources a transporter can hold
        uint256 capacity;
        /// @notice Speed of the transporter in unit per block
        uint256 speed;
        /// @notice Resources needed to build the transporter
        uint256[][] costs;
    }

    function transport(
        uint256 fromPlanetId,
        uint256 toPlanetId,
        uint256 amount,
        uint256 ships
    ) external;

    function characteristics() external view returns (Transporter memory);
}
