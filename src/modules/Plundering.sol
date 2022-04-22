// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "openzeppelin-contracts/contracts/utils/introspection/IERC165.sol";
import "openzeppelin-contracts/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

import "../SanctisModule.sol";
import "./IPlundering.sol";
import "../extensions/ICommanders.sol";
import "../extensions/IPlanets.sol";
import "../extensions/IFleets.sol";

contract Plundering is IPlundering, SanctisModule {
    /* ========== Sanctis extensions used ========== */
    bytes32 constant COMMANDERS = "COMMANDERS";
    bytes32 constant PLANETS = "PLANETS";
    bytes32 constant FLEETS = "FLEETS";

    /* ========== Contract variables ========== */
    uint8 constant PLANET_STATUS_UNKNOWN = 0;
    uint8 constant PLANET_STATUS_UNCHARTED = 1;
    uint8 constant PLANET_STATUS_COLONIZED = 2;
    uint8 constant PLANET_STATUS_SANCTIS = 3;

    uint256 constant FLEET_STATUS_PREPARING = 0;
    uint256 constant FLEET_STATUS_ORBITING = 1;
    uint256 constant FLEET_STATUS_TRAVELLING = 2;
    uint256 constant FLEET_STATUS_DESTROYED = 3;

    mapping(uint256 => uint256) internal s_lastPlundering;
    uint256 internal s_plunderPeriod;
    uint256 internal s_plunderRate;

    constructor(
        ISanctis newSanctis,
        uint256 plunderPeriod_,
        uint256 plunderRate_
    ) SanctisModule(newSanctis) {
        s_plunderPeriod = plunderPeriod_;
        s_plunderRate = plunderRate_;
    }

    /* ========== Fleets interfaces ========== */
    function plunder(uint256 fleetId, IResource resource) external {
        IFleets.Fleet memory targetFleet = IFleets(s_sanctis.extension(FLEETS))
            .fleet(fleetId);

        _assertApprovedCommander(targetFleet.commander, msg.sender);
        require(
            targetFleet.status == FLEET_STATUS_ORBITING,
            "Plundering: Status"
        );

        IPlanets.Planet memory targetPlanet = IPlanets(
            s_sanctis.extension(PLANETS)
        ).planet(targetFleet.fromPlanetId);
        require(
            targetPlanet.status == PLANET_STATUS_COLONIZED,
            "Plundering: Status"
        );
        require(
            s_lastPlundering[targetFleet.fromPlanetId] + s_plunderPeriod <=
                block.number,
            "Plundering: Too soon"
        );

        (, uint256 planetDefensivePower) = IFleets(s_sanctis.extension(FLEETS))
            .planet(targetFleet.fromPlanetId);
        require(
            targetFleet.totalOffensivePower > planetDefensivePower,
            "Plundering: Fleet weak"
        );

        s_lastPlundering[targetFleet.fromPlanetId] = block.number;
        uint256 plunderAmount = (resource.reserve(targetFleet.fromPlanetId) *
            s_plunderRate) / 10000;
        uint256 loadable = plunderAmount >= targetFleet.capacity
            ? targetFleet.capacity
            : plunderAmount;

        IFleets(s_sanctis.extension(FLEETS)).allowedLoad(
            fleetId,
            resource,
            loadable
        );
    }

    function defendPlanet(uint256 fleetId) external {
        IFleets.Fleet memory targetFleet = IFleets(s_sanctis.extension(FLEETS))
            .fleet(fleetId);
        (uint256 planetOffensivePower, ) = IFleets(s_sanctis.extension(FLEETS))
            .planet(targetFleet.fromPlanetId);
        _assertApprovedCommander(targetFleet.commander, msg.sender);
        require(
            planetOffensivePower >= targetFleet.totalDefensivePower,
            "Plundering: Planet weak"
        );
        require(
            targetFleet.status == FLEET_STATUS_ORBITING,
            "Plundering: Status"
        );

        targetFleet.status = FLEET_STATUS_DESTROYED;
        IFleets(s_sanctis.extension(FLEETS)).setFleet(fleetId, targetFleet);
    }

    function plunderPeriod() external view returns (uint256) {
        return s_plunderPeriod;
    }

    function plunderRate() external view returns (uint256) {
        return s_plunderRate;
    }

    function nextPlundering(uint256 planetId) external view returns (uint256) {
        return s_lastPlundering[planetId] + s_plunderPeriod;
    }

    function setParameters(uint256 plunderPeriod_, uint256 plunderRate_)
        external
        onlyExecutor
    {
        s_plunderPeriod = plunderPeriod_;
        s_plunderRate = plunderRate_;
    }

    /* ========== Assertions ========== */
    /// @notice Asserts that the caller can interact with the commander
    function _assertApprovedCommander(uint256 commanderId, address caller)
        internal
        view
    {
        require(
            ICommanders(s_sanctis.extension(COMMANDERS)).isApproved(
                caller,
                commanderId
            ),
            "Plundering: Not approved"
        );
    }
}
