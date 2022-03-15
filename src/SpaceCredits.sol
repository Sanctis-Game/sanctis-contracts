// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-contracts/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Votes.sol";

import "./interfaces/ISanctis.sol";

contract SpaceCredits is ERC20, ERC20Votes, Ownable {
    constructor() ERC20("Space Credits", "CRED") ERC20Permit("Space Credits") {
        _mint(msg.sender, 10 ** 27);
    }

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    // The functions below are overrides required by Solidity.

    function _afterTokenTransfer(address from, address to, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
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
