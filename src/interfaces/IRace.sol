// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

interface IRace {
    function id() external view returns (uint256);

    function name() external view returns (string memory);
}
