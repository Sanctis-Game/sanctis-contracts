// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "openzeppelin-contracts/contracts/utils/introspection/IERC165.sol";
import "openzeppelin-contracts/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

import "../interfaces/ISanctis.sol";
import "../interfaces/ICommanders.sol";
import "../interfaces/IPlanets.sol";
import "../interfaces/IGalacticStandards.sol";
import "../interfaces/IInfrastructureRegistry.sol";
import "../interfaces/IResource.sol";
import "../interfaces/IExtractors.sol";

/**
 * Abstract contract defining a base for resource handling
 */
abstract contract Resource is IResource {
    mapping(uint256 => uint256) internal _reserves;

    ISanctis public sanctis;

    uint256 internal _id;
    string internal _name;

    constructor(ISanctis sanctis_, string memory name_) {
        sanctis = sanctis_;
        _name = name_;
        _id = sanctis.resourceRegistry().create(this);
    }

    /* ========== Resource interfaces ========== */
    function id() external view returns (uint256) {
        return _id;
    }

    function name() external view returns (string memory) {
        return _name;
    }

    /**
     * @notice Let's an infrastructure or ship mint a resource to a specific planet
     * This is useful for resource transportation and consumption for building.
     * @dev Cannot be called by an unregistered operator.
     */
    function mint(
        uint256 operatorId,
        uint256 planetId,
        uint256 amount
    ) external {
        _checkIsRegisteredInfrastructureOrShip(msg.sender, operatorId);

        _reserves[planetId] += amount;
    }

    function burn(
        uint256 operatorId,
        uint256 planetId,
        uint256 amount
    ) external {
        _checkIsRegisteredInfrastructureOrShip(msg.sender, operatorId);

        _reserves[planetId] -= amount;
    }

    /// @dev Overload this function to affect rarity of the resource
    function isAvailableOnPlanet(uint256) external pure returns (bool) {
        return true;
    }

    function reserve(uint256 planetId) external view returns (uint256) {
        return _reserves[planetId];
    }

    /* ========== Helpers ========== */
    function _checkIsRegisteredInfrastructureOrShip(
        address sender,
        uint256 operatorId
    ) internal view {
        if (
            !((sanctis.standards().isAllowed(
                IGalacticStandards.StandardType.Infrastructure,
                operatorId
            ) &&
                address(
                    sanctis.infrastructureRegistry().infrastructure(operatorId)
                ) ==
                sender) ||
                (sanctis.standards().isAllowed(
                    IGalacticStandards.StandardType.Ship,
                    operatorId
                ) &&
                    address(sanctis.shipRegistry().ship(operatorId)) == sender))
        ) revert IllegitimateMinter({minter: sender});
    }
}
