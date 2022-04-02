// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "../ISanctisModule.sol";
import "../resources/IResource.sol";

interface IPlundering is ISanctisModule {
    error PlunderingTooEarly(uint256 planetId);
    error FleetTooWeak(uint256 fleetId);
    error PlanetTooWeak(uint256 planetId, uint256 received, uint256 required);

    function plunder(uint256 fleetId, IResource resource) external;

    function defendPlanet(uint256 planetId, uint256 fleetId) external;

    function plunderPeriod() external view returns (uint256);

    function plunderRate() external view returns (uint256);

    function nextPlundering(uint256 planetId) external view returns (uint256);
}
