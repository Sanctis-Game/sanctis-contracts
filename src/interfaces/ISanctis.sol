// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "openzeppelin-contracts/contracts/governance/IGovernor.sol";

import "./ISanctisExtension.sol";

interface ISanctis {
    function parliamentExecutor() external view returns (address);

    function setParliamentExecutor(address newParliamentExecutor) external;

    function allowed(address) external view returns (bool);
    
    function setAllowed(address, bool) external;

    function extension(string memory key) external view returns (address);

    function insertAndAllowExtension(ISanctisExtension object) external;

    function reloadExtension(ISanctisExtension object) external;

    function ejectAndDisallowExtension(ISanctisExtension object) external;
}
