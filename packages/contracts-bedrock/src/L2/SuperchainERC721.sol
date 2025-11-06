// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

// Contracts
import { ERC721 } from "@solady-v0.0.245/tokens/ERC721.sol";

// Libraries
import { Predeploys } from "src/libraries/Predeploys.sol";
import { Unauthorized } from "src/libraries/errors/CommonErrors.sol";

// Interfaces
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { ISemver } from "interfaces/universal/ISemver.sol";
import { IL2ToL2CrossDomainMessenger } from "interfaces/L2/IL2ToL2CrossDomainMessenger.sol";

abstract contract SuperchainERC721 is ERC721, ISemver {
    /// @notice Emitted when a crosschain transfer is initiated on the local chain.
    /// @param from The address of the owner of the token. If the owner is msg.sender, this value is ignored.
    /// @param to The address of the recipient.
    /// @param tokenId The ID of the token.
    /// @param destinationChainId The ID of the destination chain.
    /// @param msgHash The hash of the resulting message on the destination chain.
    event CrosschainTransferInitiated(
        address indexed from, address indexed to, uint256 indexed tokenId, uint256 destinationChainId, bytes32 msgHash
    );

    /// @notice Emitted when a crosschain transfer is finalized on the destination chain.
    /// @param to The address of the recipient.
    /// @param tokenId The ID of the token.
    event CrosschainTransferFinalized(address indexed to, uint256 indexed tokenId);

    /// @notice Semantic version.
    /// @custom:semver 1.0.0
    function version() external view virtual returns (string memory) {
        return "1.0.0";
    }

    /// @notice Initiates a crosschain transfer of an NFT to the destination chain.
    /// @param _from The address of the owner of the token. If the owner is msg.sender, this value is ignored.
    /// @param _to The address of the recipient.
    /// @param _tokenId The ID of the token.
    /// @param _destinationChainId The ID of the destination chain.
    function initiateCrosschainTransfer(
        address _from,
        address _to,
        uint256 _tokenId,
        uint256 _destinationChainId
    )
        external
    {
        // can only be called by the owner or an approved operator
        if (msg.sender != ownerOf(_tokenId) || isApprovedForAll(_from, msg.sender)) revert Unauthorized();

        // force-set the from parameter to the owner
        _from = ownerOf(_tokenId);

        // burn the nft here
        _burn(_tokenId);

        // send the message to the destination chain
        bytes memory message = abi.encodeCall(this.finalizeCrosschainTransfer, (_to, _tokenId));
        bytes32 msgHash = IL2ToL2CrossDomainMessenger(Predeploys.L2_TO_L2_CROSS_DOMAIN_MESSENGER).sendMessage(
            _destinationChainId, address(this), message
        );

        emit CrosschainTransferInitiated(_from, _to, _tokenId, _destinationChainId, msgHash);
    }

    /// @notice Finalizes a crosschain transfer of an NFT from the destination chain. Caller must be the
    /// L2ToL2CrossDomainMessenger.
    /// @param _to The address of the recipient.
    /// @param _tokenId The ID of the token.
    function finalizeCrosschainTransfer(address _to, uint256 _tokenId) external {
        // can only be called by the L2ToL2CrossDomainMessenger
        if (msg.sender != Predeploys.L2_TO_L2_CROSS_DOMAIN_MESSENGER) revert Unauthorized();

        // get the sender of the message
        address sender =
            IL2ToL2CrossDomainMessenger(Predeploys.L2_TO_L2_CROSS_DOMAIN_MESSENGER).crossDomainMessageSender();

        // check if the sender is the contract
        if (sender != address(this)) revert Unauthorized();

        // mint the nft here
        _mint(_to, _tokenId);

        emit CrosschainTransferFinalized(_to, _tokenId);
    }
}
