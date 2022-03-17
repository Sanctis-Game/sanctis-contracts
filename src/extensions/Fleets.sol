// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "openzeppelin-contracts/contracts/utils/introspection/IERC165.sol";
import "openzeppelin-contracts/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

import "../interfaces/ISanctis.sol";
import "../interfaces/ICommanders.sol";
import "../interfaces/IPlanets.sol";
import "../interfaces/IFleets.sol";
import "../interfaces/IShip.sol";
import "../SanctisExtension.sol";

contract Fleets is IFleets, SanctisExtension {
    mapping(uint256 => Fleet) internal _fleets;
    mapping(address => uint256) internal _shipsPerFleet;

    constructor(ISanctis newSanctis) SanctisExtension("FLEETS", newSanctis) {}

    /* ========== Fleets interfaces ========== */
    function fleet(uint256 fleetId) external view returns (Fleet memory) {
        return _fleets[fleetId];
    }

    function createFleet(
        uint256 fleetId,
        uint256 commanderId,
        uint256 planetId
    ) public {
        Fleet memory targetFleet = _fleets[fleetId];

        if (targetFleet.commander != 0)
            revert AlreadyExists({fleetId: fleetId});

        targetFleet.commander = commanderId;
        targetFleet.fromPlanetId = planetId;

        _fleets[fleetId] = targetFleet;
    }

    function addToFleet(
        uint256 fleetId,
        IShip ship,
        uint256 amount
    ) public {
        Fleet memory targetFleet = _fleets[fleetId];

        if (
            !ICommanders(sanctis.extension("COMMANDERS")).isApproved(
                msg.sender,
                targetFleet.commander
            )
        ) revert NotCommanderOwner({commanderId: targetFleet.commander});

        if (targetFleet.status != FleetStatus.Preparing)
            revert AlreadyMoving({fleetId: fleetId});

        targetFleet.totalSpeed += amount * ship.speed();
        targetFleet.ships += amount;
        _fleets[fleetId] = targetFleet;

        _shipsPerFleet[address(ship)] += amount;
        ship.burn(targetFleet.fromPlanetId, amount);
    }

    function removeFromFleet(
        uint256 fleetId,
        IShip ship,
        uint256 amount
    ) public {
        Fleet memory targetFleet = _fleets[fleetId];

        if (
            !ICommanders(sanctis.extension("COMMANDERS")).isApproved(
                msg.sender,
                targetFleet.commander
            )
        ) revert NotCommanderOwner({commanderId: targetFleet.commander});

        if (targetFleet.status != FleetStatus.Preparing)
            revert AlreadyMoving({fleetId: fleetId});

        targetFleet.totalSpeed -= amount * ship.speed();
        targetFleet.ships -= amount;
        _fleets[fleetId] = targetFleet;

        _shipsPerFleet[address(ship)] -= amount;
        ship.mint(targetFleet.fromPlanetId, amount);
    }

    function moveFleet(uint256 fleetId, uint256 toPlanetId) external {
        Fleet memory targetFleet = _fleets[fleetId];

        if (
            !ICommanders(sanctis.extension("COMMANDERS")).isApproved(
                msg.sender,
                targetFleet.commander
            )
        ) revert NotCommanderOwner({commanderId: targetFleet.commander});

        if (targetFleet.status != FleetStatus.Preparing)
            revert AlreadyMoving({fleetId: fleetId});

        if(IPlanets(sanctis.extension("PLANETS")).planet(toPlanetId).status == IPlanets.PlanetStatus.Unknown)
            revert IPlanets.InvalidPlanet({ planet: toPlanetId });

        targetFleet.status = FleetStatus.Travelling;
        targetFleet.toPlanetId = toPlanetId;
        targetFleet.arrivalBlock =
            block.number +
            IPlanets(sanctis.extension("PLANETS")).distance(
                targetFleet.fromPlanetId,
                toPlanetId
            ) /
            (targetFleet.totalSpeed / targetFleet.ships);

        _fleets[fleetId] = targetFleet;
    }

    function settleFleet(uint256 fleetId) external {
        Fleet memory targetFleet = _fleets[fleetId];

        if (
            targetFleet.status != FleetStatus.Travelling &&
            targetFleet.arrivalBlock > block.number
        ) revert NotArrivedYet({fleetId: fleetId});

        targetFleet.status = FleetStatus.Preparing;
        targetFleet.fromPlanetId = targetFleet.toPlanetId;
        targetFleet.arrivalBlock = 0;

        _fleets[fleetId] = targetFleet;
    }
}
