// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { ISemver } from "interfaces/universal/ISemver.sol";
import { IERC721Solady as IERC721 } from "interfaces/vendor/IERC721Solady.sol";

/// @title ISuperchainERC721
/// @notice Interface for the SuperchainERC721 contract.
interface ISuperchainERC721 is ISemver, IERC721 {
    event CrosschainMint(address indexed to, uint256 indexed tokenId);
    event CrosschainBurn(address indexed from, uint256 indexed tokenId);

    function crosschainMint(address _to, uint256 _tokenId) external;
    function crosschainBurn(address _from, uint256 _tokenId) external;
}
