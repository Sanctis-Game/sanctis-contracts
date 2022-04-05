// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./ISanctisExtension.sol";
import "./SanctisModule.sol";

abstract contract SanctisExtension is SanctisModule, ISanctisExtension {
    bytes32 s_key;

    constructor(bytes32 _key, ISanctis _sanctis) SanctisModule(_sanctis) {
        s_key = _key;
    }

    function key() external view returns (bytes32) {
        return s_key;
    }
}
