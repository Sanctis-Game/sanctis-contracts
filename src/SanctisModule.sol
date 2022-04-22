// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./ISanctisModule.sol";

contract SanctisModule is ISanctisModule {
    ISanctis public s_sanctis;

    constructor(ISanctis _sanctis) {
        s_sanctis = _sanctis;
    }

    modifier onlySanctis() {
        require(address(s_sanctis) == msg.sender, "Module: Sanctis");
        _;
    }

    modifier onlyExecutor() {
        require(
            s_sanctis.parliamentExecutor() == msg.sender,
            "Module: Executor"
        );
        _;
    }

    modifier onlyAllowed() {
        require(s_sanctis.allowed(msg.sender), "Module: Allowed");
        _;
    }

    function sanctis() public view onlyExecutor returns (ISanctis) {
        return s_sanctis;
    }

    function changeSanctis(ISanctis newSanctis) public onlyExecutor {
        s_sanctis = newSanctis;
    }
}
