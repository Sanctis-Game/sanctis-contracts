// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

interface IGalacticStandards {
    /// @notice Types of assets subject to Sanctis governance
    enum StandardType {
        Race,
        Resource,
        Infrastructure,
        Ship
    }

    function add(StandardType standard, uint256 id) external;

    function remove(StandardType standard, uint256 id) external;

    function isAllowed(StandardType standard, uint256 id)
        external
        view
        returns (bool);

    function count(StandardType standard) external view returns (uint256);

    function getByIndex(StandardType standard, uint256 index)
        external
        view
        returns (uint256);
}
