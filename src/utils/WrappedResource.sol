// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";

import "../interfaces/IResource.sol";

contract WrappedResource is ERC20, Ownable {
    constructor(IResource resource, uint256 planetId)
        ERC20(
            string(abi.encodePacked(resource.name(), " of ", planetId)),
            resource.symbol()
        )
    {}

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }
    
    function burn(address to, uint256 amount) external onlyOwner {
        _burn(to, amount);
    }
}
