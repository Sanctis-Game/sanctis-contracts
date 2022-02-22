// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "openzeppelin-contracts/contracts/utils/introspection/IERC165.sol";
import "openzeppelin-contracts/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

import "./interfaces/IShipRegistry.sol";

contract ShipRegistry is IShipRegistry {
    mapping(uint256 => IShip) private _ships;
    uint256 private _registeredShips;

    function create(IShip newShip)
        external
        returns (uint256)
    {
        _registeredShips++;
        _ships[
            _registeredShips
        ] = newShip;
        return _registeredShips;
    }

    function registeredShips() external view returns (uint256) {
        return _registeredShips;
    }

    function ship(uint256 shipId)
        external
        view
        returns (IShip)
    {
        return _ships[shipId];
    }
}
