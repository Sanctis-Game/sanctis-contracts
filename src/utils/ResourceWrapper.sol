// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

import "../interfaces/ISanctis.sol";
import "../interfaces/ICommanders.sol";
import "../interfaces/IPlanets.sol";
import "../interfaces/IResource.sol";
import "../interfaces/IFleets.sol";
import "../SanctisModule.sol";
import "./WrappedResource.sol";

contract ResourceWrapper is SanctisModule {
    /* ========== Sanctis extensions used ========== */
    string constant COMMANDERS = "COMMANDERS";
    string constant PLANETS = "PLANETS";
    string constant FLEETS = "FLEETS";

    /* ========== Contract variables ========== */
    mapping(uint256 => mapping(address => WrappedResource)) internal _tokens;

    constructor(ISanctis sanctis) SanctisModule(sanctis) {}

    function mintFromFleet(
        uint256 fleetId,
        IResource resource,
        uint256 amount
    ) external {
        // Unloading on the planet
        IFleets(sanctis.extension(FLEETS)).unload(fleetId, resource, amount);

        // Emitting planet-specific tokens acting as IOUs
        IFleets.Fleet memory fleet = IFleets(sanctis.extension(FLEETS)).fleet(
            fleetId
        );
        if (
            address(_tokens[fleet.fromPlanetId][address(resource)]) ==
            address(0)
        )
            _tokens[fleet.fromPlanetId][
                address(resource)
            ] = new WrappedResource(resource, fleet.fromPlanetId);

        _tokens[fleet.fromPlanetId][address(resource)].mint(msg.sender, amount);
    }

    function burnToFleet(
        uint256 fleetId,
        IResource resource,
        uint256 amount
    ) external {
        // Burning planet-specific tokens acting as IOUs
        // It will fail if the token does not exist or the balance is invalid
        _tokens[IFleets(sanctis.extension(FLEETS)).fleet(fleetId).fromPlanetId][
            address(resource)
        ].burn(msg.sender, amount);

        // Loading the fleet on the planet
        IFleets(sanctis.extension(FLEETS)).load(fleetId, resource, amount);
    }

    function getToken(IResource resource, uint256 planetId)
        external
        view
        returns (address)
    {
        return address(_tokens[planetId][address(resource)]);
    }
}
