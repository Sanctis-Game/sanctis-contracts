// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-contracts/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Votes.sol";

import "./ISpaceCredits.sol";
import "../SanctisExtension.sol";

contract SpaceCredits is SanctisExtension, ERC20, ERC20Permit, ERC20Votes {
    /* ========== Sanctis extensions used ========== */
    bytes32 constant CREDITS = bytes32("CREDITS");

    constructor(ISanctis _sanctis)
        ERC20("Space Credits", "CRED")
        ERC20Permit("Space Credits")
        SanctisExtension(CREDITS, _sanctis)
    {}

    function mint(address to, uint256 amount) external onlyExecutor {
        _mint(to, amount);
    }

    // The functions below are overrides required by Solidity.

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20, ERC20Votes) {
        super._afterTokenTransfer(from, to, amount);
    }

    function _mint(address to, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._mint(to, amount);
    }

    function _burn(address account, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._burn(account, amount);
    }
}
