// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./IInfrastructure.sol";
import "../ships/IShip.sol";

interface ISpatioports is IInfrastructure {
    function build(
        uint256 planetId,
        IShip fleet,
        uint256 amount
    ) external;

    function discountFactor() external view returns (uint256);

    function currentDiscount(uint256 planetId) external view returns (uint256);

    function nextDiscount(uint256 planetId) external view returns (uint256);
}
