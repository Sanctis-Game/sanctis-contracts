// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./ISanctisExtension.sol";
import "./SanctisModule.sol";

abstract contract SanctisExtension is SanctisModule, ISanctisExtension {
    bytes32 _key;

    constructor(bytes32 key_, ISanctis _sanctis) SanctisModule(_sanctis) {
        _key = key_;
    }

    function key() external view returns (bytes32) {
        return _key;
    }
}
