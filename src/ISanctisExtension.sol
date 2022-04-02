// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./ISanctisModule.sol";

interface ISanctisExtension is ISanctisModule {
    function key() external view returns (bytes32);
}
