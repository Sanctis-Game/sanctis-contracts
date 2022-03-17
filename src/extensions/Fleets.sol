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

        if (targetFleet.speed > ship.speed())
            _fleets[fleetId].speed = ship.speed();

        _shipsPerFleet[address(ship)] += amount;
        ship.destroy(targetFleet.fromPlanetId, amount);
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

        // TODO: Increase fleet's speed if there are 0 of the slower ship

        _shipsPerFleet[address(ship)] -= amount;
        ship.build(targetFleet.fromPlanetId, amount);
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

        _fleets[fleetId].status = FleetStatus.Travelling;
        _fleets[fleetId].toPlanetId = toPlanetId;
        _fleets[fleetId].arrivalBlock =
            block.number +
            IPlanets(sanctis.extension("PLANETS")).distance(
                targetFleet.fromPlanetId,
                toPlanetId
            ) /
            targetFleet.speed;
    }
}
