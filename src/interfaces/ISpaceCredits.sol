// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-contracts/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface ISpaceCredits is IERC20Metadata, IERC20Permit, IVotes {
    function mint(address to, uint256 amount) external;
}
