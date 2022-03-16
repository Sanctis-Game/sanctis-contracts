// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./ISanctis.sol";

interface ISanctisModule {
    function changeSanctis(ISanctis newSanctis) external;
}
