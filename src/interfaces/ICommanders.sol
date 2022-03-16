// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "openzeppelin-contracts/contracts/token/ERC721/extensions/IERC721Metadata.sol";

import "./IRace.sol";

interface ICommanders is IERC721Metadata {
    error CommanderZero();
    error NotTheCitadel(address caller);

    struct Commander {
        /// @notice Name of the citizen
        string name;
        /// @notice Address of the race contract
        IRace race;
        /// @notice Time of onboarding the Sanctis
        uint256 onboarding;
    }

    function create(string memory name, IRace race) external;

    function created() external view returns (uint256);

    function onboard(uint256 commanderId) external;

    function offboard(uint256 commanderId) external;

    function commander(uint256 commanderId) external view returns (Commander memory);
}
