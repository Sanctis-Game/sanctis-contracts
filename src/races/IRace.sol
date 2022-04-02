// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "../ISanctisModule.sol";

interface IRace is ISanctisModule {
    function name() external view returns (string memory);
}
