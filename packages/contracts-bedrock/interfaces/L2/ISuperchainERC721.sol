// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import { ISemver } from "interfaces/universal/ISemver.sol";

/// @title ISuperchainERC721
/// @notice Interface for the SuperchainERC721 contract.
interface ISuperchainERC721 is ISemver {
    event CrosschainTransferInitiated(
        address indexed from, address indexed to, uint256 indexed tokenId, uint256 destinationChainId, bytes32 msgHash
    );

    event CrosschainTransferFinalized(address indexed to, uint256 indexed tokenId);

    function initiateCrosschainTransfer(
        address _from,
        address _to,
        uint256 _tokenId,
        uint256 _destinationChainId
    )
        external;

    function finalizeCrosschainTransfer(address _to, uint256 _tokenId) external;
}
