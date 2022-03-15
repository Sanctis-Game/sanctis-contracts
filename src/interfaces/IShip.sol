// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./Cost.sol";
import "./ISanctis.sol";

interface IShip {
    error UnauthorizedPlayer(address player, uint256 planet);
    error UnauthorizedOperator(uint256 operator);
    error InvalidFleet(uint256 fleet);
    error NotEnoughReserve(uint256 planet, uint256 amount);
    error PlanetNotOwned(address player, uint256 planet);

    function id() external view returns (uint256);

    function unitCosts() external view returns (Cost[] memory);

    function reserve(uint256 planetId) external view returns (uint256);

    function inFleet(uint256 fleetId) external view returns (uint256);

    function build(
        uint256 infrastructureId,
        uint256 planetId,
        uint256 amount
    ) external;

    function destroy(
        uint256 infrastructureId,
        uint256 planetId,
        uint256 amount
    ) external;

    function addToFleet(
        uint256 fleetId,
        uint256 planetId,
        uint256 amount
    ) external;

    function removeFromFleet(
        uint256 fleetId,
        uint256 planetId,
        uint256 amount
    ) external;
}
