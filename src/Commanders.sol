// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

import "./interfaces/ICommanders.sol";
import "./interfaces/IPlanets.sol";
import "./interfaces/ISanctis.sol";

contract Commanders is ICommanders, ERC721Enumerable, Ownable {
    mapping(uint256 => Commander) private _commanders;
    uint256 private _createdCommanders;

    ISanctis public sanctis;

    constructor(ISanctis newSanctis) ERC721("Commanders", "CITIZEN") {
        transferOwnership(address(newSanctis.parliamentExecutor()));
        sanctis = newSanctis;
    }

    function create(string memory name, IRace race) external {
        require(validateName(name), "Commanders: Invalid name");
        _createdCommanders++;
        _commanders[_createdCommanders] = Commander({
            name: name,
            race: race,
            onboarding: 0
        });
        _mint(msg.sender, _createdCommanders);
    }

    function onboard(uint256 citizenId) external {
        if (msg.sender != address(sanctis))
            revert NotTheCitadel({caller: msg.sender});

        _commanders[citizenId].onboarding = block.timestamp;
    }

    function offboard(uint256 citizenId) external {
        if (msg.sender != address(sanctis))
            revert NotTheCitadel({caller: msg.sender});

        _commanders[citizenId].onboarding = 0;
    }

    /* ========== CITIZENSHIP ========== */
    function commander(uint256 commanderId) external view returns (Commander memory) {
        return _commanders[commanderId];
    }

    function created() external view returns (uint256) {
        return _createdCommanders;
    }

    // @dev Check if the name string is valid (Alphanumeric and spaces without leading or trailing space)
    function validateName(string memory str) public pure returns (bool) {
        bytes memory b = bytes(str);
        if (b.length < 1) return false;
        if (b.length > 25) return false; // Cannot be longer than 25 characters
        if (b[0] == 0x20) return false; // Leading space
        if (b[b.length - 1] == 0x20) return false; // Trailing space

        bytes1 last_char = b[0];

        for (uint256 i; i < b.length; i++) {
            bytes1 char = b[i];

            if (char == 0x20 && last_char == 0x20) return false; // Cannot contain continous spaces

            if (
                !(char >= 0x30 && char <= 0x39) && //9-0
                !(char >= 0x41 && char <= 0x5A) && //A-Z
                !(char >= 0x61 && char <= 0x7A) && //a-z
                !(char == 0x20) //space
            ) return false;

            last_char = char;
        }

        return true;
    }
}
