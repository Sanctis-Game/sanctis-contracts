// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./ISanctisModule.sol";

contract SanctisModule is ISanctisModule {
    error NotTheSanctis(address sender);
    error NotTheExecutor(address sender);
    error NotAllowed(address sender);

    ISanctis public s_sanctis;

    constructor(ISanctis _sanctis) {
        s_sanctis = _sanctis;
    }

    modifier onlySanctis() {
        if (address(s_sanctis) != msg.sender)
            revert NotTheSanctis({sender: msg.sender});
        _;
    }

    modifier onlyExecutor() {
        if (s_sanctis.parliamentExecutor() != msg.sender)
            revert NotTheExecutor({sender: msg.sender});
        _;
    }

    modifier onlyAllowed() {
        if (!s_sanctis.allowed(msg.sender))
            revert NotAllowed({sender: msg.sender});
        _;
    }

    function sanctis() public view onlyExecutor returns (ISanctis) {
        return s_sanctis;
    }

    function changeSanctis(ISanctis newSanctis) public onlyExecutor {
        s_sanctis = newSanctis;
    }
}
