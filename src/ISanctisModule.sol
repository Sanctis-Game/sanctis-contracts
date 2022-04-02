// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./ISanctis.sol";

interface ISanctisModule {
    function sanctis() external view returns (ISanctis);

    function changeSanctis(ISanctis newSanctis) external;
}
