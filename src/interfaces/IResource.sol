// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IResource {
    error Unallowed(address sender);

    function name() external view returns (string memory);

    function mint(
        uint256 planetId,
        uint256 amount
    ) external;

    function burn(
        uint256 planetId,
        uint256 amount
    ) external;

    function isAvailableOnPlanet(uint256 planetId) external view returns (bool);

    function reserve(uint256 planetId) external view returns (uint256);
}
