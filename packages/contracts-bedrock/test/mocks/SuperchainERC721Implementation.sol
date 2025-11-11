// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import { SuperchainERC721 } from "src/L2/SuperchainERC721.sol";

/// @title SuperchainERC721Implementation Mock contract
/// @notice Mock contract just to create tests over an implementation of the SuperchainERC721 abstract contract.
contract MockSuperchainERC721Implementation is SuperchainERC721 {
    constructor() SuperchainERC721() { }

    function name() public view override returns (string memory) {
        return "SuperchainERC721";
    }

    function symbol() public view override returns (string memory) {
        return "SCE";
    }

    function tokenURI(uint256 _id) public view override returns (string memory) {
        return "https://superchain.com/tokenURI/{_id}";
    }

    function mint(address _to, uint256 _tokenId) public {
        _mint(_to, _tokenId);
    }
}
