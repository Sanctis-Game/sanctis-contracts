// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./IInfrastructure.sol";

interface IInfrastructureRegistry {
    function create(IInfrastructure newInfrastructure)
        external
        returns (uint256);

    function registeredInfrastructures() external view returns (uint256);

    function infrastructure(uint256 infrastructureId)
        external
        view
        returns (IInfrastructure);
}
