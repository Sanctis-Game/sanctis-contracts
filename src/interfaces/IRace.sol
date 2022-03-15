// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IRace {
    function id() external view returns (uint256);

    function name() external view returns (string memory);
}
