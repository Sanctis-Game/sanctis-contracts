// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./interfaces/ISanctis.sol";
import "./interfaces/ISanctisModule.sol";

contract SanctisModule is ISanctisModule {
    error NotTheSanctis(address sender);
    error NotTheExecutor(address sender);
    error NotAllowed(address sender);

    ISanctis public sanctis;

    constructor(ISanctis _sanctis) {
        sanctis = _sanctis;
    }

    modifier onlySanctis() {
        if(address(sanctis) != msg.sender) revert NotTheSanctis({ sender: msg.sender });
        _;
    }

    modifier onlyExecutor() {
        if(sanctis.parliamentExecutor() != msg.sender) revert NotTheExecutor({ sender: msg.sender });
        _;
    }

    modifier onlyAllowed() {
        if(!sanctis.allowed(msg.sender)) revert NotAllowed({ sender: msg.sender });
        _;
    }

    function changeSanctis(ISanctis newSanctis) public onlyExecutor {
        sanctis = newSanctis;
    }
}