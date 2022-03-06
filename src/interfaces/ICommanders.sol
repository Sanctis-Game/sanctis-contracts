// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "openzeppelin-contracts/contracts/token/ERC721/extensions/IERC721Metadata.sol";

interface ICommanders is IERC721Metadata {
    error CommanderZero();
    error NotTheCitadel(address caller);

    struct Commander {
        /// @notice Name of the citizen
        string name;
        /// @notice Id of the race
        uint256 raceId;
        /// @notice Time of onboarding the Sanctis
        uint256 onboarding;
    }

    function create(string memory name, uint256 raceId) external;

    function created() external view returns (uint256);

    function onboard(uint256 commanderId) external;

    function offboard(uint256 commanderId) external;

    function commander(uint256 commanderId) external view returns (Commander memory);
}
