// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

// Contracts
import { ERC721 } from "@solady-v0.0.245/tokens/ERC721.sol";

// Libraries
import { Predeploys } from "src/libraries/Predeploys.sol";
import { Unauthorized } from "src/libraries/errors/CommonErrors.sol";

// Interfaces
import { ISemver } from "interfaces/universal/ISemver.sol";

abstract contract SuperchainERC721 is ERC721, ISemver {
    /// @notice Emitted when a crosschain mint is initiated on the local chain.
    /// @param to The address of the recipient.
    /// @param tokenId The ID of the token.
    event CrosschainMint(address indexed to, uint256 indexed tokenId);

    /// @notice Emitted when a crosschain burn is performed on the local chain.
    /// @param from The address of the owner of the token.
    /// @param tokenId The ID of the token.
    event CrosschainBurn(address indexed from, uint256 indexed tokenId);

    /// @notice Semantic version.
    /// @custom:semver 1.0.0
    function version() external view virtual returns (string memory) {
        return "1.0.0";
    }

    /// @notice Allows the SuperchainTokenBridge to mint tokens.
    /// @param _to     Address to mint tokens to.
    /// @param _tokenId Token ID to mint.
    function crosschainMint(address _to, uint256 _tokenId) external {
        if (msg.sender != Predeploys.SUPERCHAIN_TOKEN_BRIDGE) revert Unauthorized();

        _mint(_to, _tokenId);

        emit CrosschainMint(_to, _tokenId);
    }

    /// @notice Allows the SuperchainTokenBridge to burn tokens.
    /// @param _from   Address to burn tokens from.
    /// @param _tokenId Token ID to burn.
    function crosschainBurn(address _from, uint256 _tokenId) external {
        if (msg.sender != Predeploys.SUPERCHAIN_TOKEN_BRIDGE) revert Unauthorized();

        _burn(_from, _tokenId);

        emit CrosschainBurn(_from, _tokenId);
    }
}
