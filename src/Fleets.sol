// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "openzeppelin-contracts/contracts/utils/introspection/IERC165.sol";
import "openzeppelin-contracts/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

import "./interfaces/ISanctis.sol";
import "./interfaces/ICommanders.sol";
import "./interfaces/IPlanets.sol";
import "./interfaces/IFleets.sol";
import "./SanctisModule.sol";

contract Fleets is IFleets, SanctisModule {
    mapping(uint256 => Fleet) internal _fleets;

    constructor(
        ISanctis newSanctis
    ) SanctisModule(newSanctis) {}

    /* ========== Fleets interfaces ========== */
    function fleet(uint256 fleetId) external view returns (Fleet memory) {
        return _fleets[fleetId];
    }

    function moveFleet(uint256 fromPlanetId, uint256 toPlanetId) external {
        // // TODO: Transfers should check ships, resources, planet ownership
        // _checkIsPlanetOwner(msg.sender, fromPlanetId);
        // // TODO: Burning should check whether infrastructure or fleet.
        // sanctis.resourceRegistry().resource(resourceId).burn(
        //     _id,
        //     toPlanetId,
        //     amount
        // );
        // Fleet[] storage userFleets = _fleets[
        //     sanctis.planets().planet(fromPlanetId).ruler
        // ];
        // userFleets.push(
        //     Fleet({
        //         fromPlanetId: fromPlanetId,
        //         toPlanetId: toPlanetId,
        //         arrivalBlock: block.number +
        //             sanctis.planets().distance(fromPlanetId, toPlanetId) /
        //             _characteristics.speed
        //     })
        // );
    }

    /* ========== Helpers ========== */
    // function _checkIsPlanetOwner(address player, uint256 planetId)
    //     internal
    //     view
    // {
    //     if (
    //         player !=
    //         sanctis.commanders().ownerOf(
    //             sanctis.planets().planet(planetId).ruler
    //         )
    //     ) revert PlanetNotOwned({planetId: planetId});
    // }

    // function _checkAuthorized(address player, uint256 planetId)
    //     internal
    //     view
    // {
    //     if (
    //         player !=
    //         sanctis.commanders().ownerOf(
    //             sanctis.planets().planet(planetId).ruler
    //         )
    //     ) revert Unauthorized({planetId: planetId});
    // }

    // function _checkPlanetHasReserves(uint256 planetId, uint256 amount)
    //     internal
    //     view
    // {
    //     if (_reserves[planetId] < amount)
    //         revert NotEnoughResource({planetId: planetId, resourceId: _id});
    // }

    // function _checkIsInfrastructure(address sender, uint256 infrastructureId)
    //     internal
    //     view
    // {
    //     if (
    //         address(
    //             sanctis.infrastructureRegistry().infrastructure(
    //                 infrastructureId
    //             )
    //         ) != sender
    //     ) revert IllegitimateMinter({minter: sender});
    // }
}
