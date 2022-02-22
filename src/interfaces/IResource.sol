// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

interface IResource {
    error IllegitimateMinter(address minter);

    function id() external view returns (uint256);

    function name() external view returns (string memory);

    function mint(
        uint256 operatorId,
        uint256 planetId,
        uint256 amount
    ) external;

    function burn(
        uint256 operatorId,
        uint256 planetId,
        uint256 amount
    ) external;

    function isAvailableOnPlanet(uint256 planetId) external view returns (bool);

    function reserve(uint256 planetId) external view returns (uint256);
}
