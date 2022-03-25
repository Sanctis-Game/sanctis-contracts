// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./Quantity.sol";
import "./IResource.sol";

interface IInfrastructure {
    error ResourceNotOnPlanet(uint256 planetId, IResource resource);
    error PlanetNotOwned(uint256 planetId);
    error NotEnoughResource(uint256 planetId, IResource resource);
    error TooSoonToUpgrade(uint256 planetId, uint256 soonestUpgrade);
    error InfrastructureDoesNotExist(address infrastructure, uint256 planetId);

    function level(uint256 planetId) external view returns (uint256);

    function costsNextLevel(uint256 planetId) external view returns (Quantity[] memory);

    function create(uint256 planetId) external;

    function upgrade(uint256 planetId) external;
}
