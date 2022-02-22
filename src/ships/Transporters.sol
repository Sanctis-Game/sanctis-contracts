// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "openzeppelin-contracts/contracts/utils/introspection/IERC165.sol";
import "openzeppelin-contracts/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

import "../interfaces/ISanctis.sol";
import "../interfaces/ICommanders.sol";
import "../interfaces/IPlanets.sol";
import "../interfaces/IGalacticStandards.sol";
import "../interfaces/IShipRegistry.sol";
import "../interfaces/IFleets.sol";
import "../interfaces/ITransporters.sol";
import "./Ship.sol";

contract Transporters is ITransporters, Ship {
    struct ShipsInFleet {
        uint256 amount;
        uint256[][] transportedResources;
    }

    uint256 internal _capacity;

    constructor(
        ISanctis newSanctis,
        uint256 newCapacity,
        uint256 speed,
        uint256[2][10] memory costs
    ) Ship(newSanctis, speed, costs) {
        _capacity = newCapacity;
    }

    /* ========== Transporter interfaces ========== */
    function transport(
        uint256 fromPlanetId,
        uint256 toPlanetId,
        uint256 amount,
        uint256 ships
    ) public {}

    function characteristics() external view returns (Transporter memory) {
        return
            Transporter({
                capacity: _capacity,
                speed: _speed,
                costs: _unitCosts
            });
    }
}
