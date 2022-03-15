// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./Cost.sol";

interface IInfrastructure {
    error ResourceNotOnPlanet(uint256 planetId, uint256 resourceId);
    error PlanetNotOwned(uint256 planetId);
    error NotEnoughResource(uint256 planetId, uint256 resourceId);
    error TooSoonToUpgrade(uint256 planetId, uint256 soonestUpgrade);

    function id() external view returns (uint256);

    function create(uint256 planetId) external;

    function upgrade(uint256 planetId) external;

    function level(uint256 planetId) external view returns (uint256);

    function costsNextLevel(uint256 planetId)
        external
        view
        returns (Cost[] memory);
}
