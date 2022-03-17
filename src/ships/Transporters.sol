// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "openzeppelin-contracts/contracts/utils/introspection/IERC165.sol";
import "openzeppelin-contracts/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

import "../interfaces/ISanctis.sol";
import "../interfaces/ICommanders.sol";
import "../interfaces/IPlanets.sol";
import "../interfaces/IFleets.sol";
import "../interfaces/ITransporters.sol";
import "./Ship.sol";

contract Transporters is ITransporters, Ship {
    struct ShipsInFleet {
        uint256 amount;
        Cost[] transportedResources;
    }

    uint256 internal _capacity;
    mapping(IResource => mapping(uint256 => uint256)) internal _stockPerFleet;

    constructor(
        ISanctis newSanctis,
        uint256 newCapacity,
        uint256 speed,
        Cost[] memory costs
    ) Ship(newSanctis, speed, costs) {
        _capacity = newCapacity;
    }

    /* ========== Transporter interfaces ========== */
    function addToFleet(
        uint256 fleetId,
        uint256 ships,
        IResource resource,
        uint256 quantity
    ) public {
        if(_capacity * ships < quantity) revert NotEnoughCapacity({ maxCapacity: _capacity * ships });
        
        _stockPerFleet[resource][fleetId] += quantity;
        resource.burn(IFleets(sanctis.extension("FLEETS")).fleet(fleetId).fromPlanetId, quantity);
        IFleets(sanctis.extension("FLEETS")).addToFleet(fleetId, this, ships);
    }

    function unload(
        uint256 fleetId,
        IResource resource,
        uint256 quantity
    ) public {
        if(_stockPerFleet[resource][fleetId] < quantity) revert NotEnoughCapacity({ maxCapacity: _stockPerFleet[resource][fleetId] });
        
        _stockPerFleet[resource][fleetId] -= quantity;
        resource.mint(IFleets(sanctis.extension("FLEETS")).fleet(fleetId).fromPlanetId, quantity);
    }

    function characteristics() external view returns (Transporter memory) {
        return
            Transporter({
                capacity: _capacity,
                speed: _speed,
                costs: _unitCosts
            });
    }
}
