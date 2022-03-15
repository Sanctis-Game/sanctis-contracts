// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./IShip.sol";

interface IShipRegistry {
    error ShipZero();
    
    function create(IShip newShip) external returns (uint256);

    function ship(uint256 shipId) external view returns (IShip);

    function registeredShips() external view returns (uint256);
}
