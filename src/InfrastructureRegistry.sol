// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "openzeppelin-contracts/contracts/utils/introspection/IERC165.sol";
import "openzeppelin-contracts/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

import "./interfaces/IInfrastructureRegistry.sol";
import "./interfaces/IInfrastructure.sol";

contract InfrastructureRegistry is IInfrastructureRegistry {
    mapping(uint256 => IInfrastructure) private _infrastructures;
    uint256 private _registeredInfrastructures;

    function create(IInfrastructure newInfrastructure)
        external
        returns (uint256)
    {
        _registeredInfrastructures++;
        _infrastructures[_registeredInfrastructures] = newInfrastructure;
        return _registeredInfrastructures;
    }

    function registeredInfrastructures() external view returns (uint256) {
        return _registeredInfrastructures;
    }

    function infrastructure(uint256 infrastructureId)
        external
        view
        returns (IInfrastructure)
    {
        return _infrastructures[infrastructureId];
    }
}
