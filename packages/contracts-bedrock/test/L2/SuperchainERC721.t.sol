// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

// Testing utilities
import { Test } from "forge-std/Test.sol";

// Libraries
import { Predeploys } from "src/libraries/Predeploys.sol";

// Target contract
import { SuperchainERC721 } from "src/L2/SuperchainERC721.sol";
import { ERC721 } from "@solady-v0.0.245/tokens/ERC721.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { ISuperchainERC721 } from "interfaces/L2/ISuperchainERC721.sol";
import { MockSuperchainERC721Implementation } from "test/mocks/SuperchainERC721Implementation.sol";
import { Unauthorized } from "src/libraries/errors/CommonErrors.sol";

/// @title SuperchainERC721_TestInit
/// @notice Reusable test initialization for `SuperchainERC721` tests.
abstract contract SuperchainERC721_TestInit is Test {
    address internal constant ZERO_ADDRESS = address(0);
    address internal constant SUPERCHAIN_TOKEN_BRIDGE = Predeploys.SUPERCHAIN_TOKEN_BRIDGE;

    MockSuperchainERC721Implementation public superchainERC721;

    /// @notice Sets up the test suite.
    function setUp() public {
        superchainERC721 = new MockSuperchainERC721Implementation();
    }

    /// @notice Helper function to setup a mock and expect a call to it.
    function _mockAndExpect(address _receiver, bytes memory _calldata, bytes memory _returned) internal {
        vm.mockCall(_receiver, _calldata, _returned);
        vm.expectCall(_receiver, _calldata);
    }
}

/// @title SuperchainERC721_Version_Test
/// @notice Tests the `version` function of the `SuperchainERC721` contract.
contract SuperchainERC721_Version_Test is SuperchainERC721_TestInit {
    /// @notice Tests that the `version` function returns the correct version string.
    function test_version_succeeds() public view {
        assertEq(superchainERC721.version(), "1.0.0");
    }
}

/// @title SuperchainERC721_CrosschainMint_Test
/// @notice Tests the `crosschainMint` function of the `SuperchainERC721` contract.
contract SuperchainERC721_CrosschainMint_Test is SuperchainERC721_TestInit {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event CrosschainMint(address indexed to, uint256 indexed tokenId);

    /// @notice Tests the `crosschainMint` function reverts when the caller is not the bridge.
    function testFuzz_crosschainMint_callerNotBridge_reverts(address _caller, address _to, uint256 _tokenId) public {
        // Ensure the caller is not the bridge
        vm.assume(_caller != SUPERCHAIN_TOKEN_BRIDGE);

        // Expect the revert with `Unauthorized` selector
        vm.expectRevert(Unauthorized.selector);

        // Call the `crosschainMint` function with the non-bridge caller
        vm.prank(_caller);
        superchainERC721.crosschainMint(_to, _tokenId);
    }

    /// @notice Tests the `crosschainMint` succeeds and emits the `CrosschainMint` event.
    function testFuzz_crosschainMint_succeeds(address _to, uint256 _tokenId) public {
        // Ensure `_to` is not the zero address
        vm.assume(_to != ZERO_ADDRESS);

        // Get the balance of `_to` before the mint to compare later on the assertions
        uint256 _toBalanceBefore = superchainERC721.balanceOf(_to);

        // Look for the emit of the `Transfer` event
        vm.expectEmit(address(superchainERC721));
        emit Transfer(ZERO_ADDRESS, _to, _tokenId);

        // Look for the emit of the `CrosschainMint` event
        vm.expectEmit(address(superchainERC721));
        emit CrosschainMint(_to, _tokenId);

        // Call the `crosschainMint` function with the bridge caller
        vm.prank(SUPERCHAIN_TOKEN_BRIDGE);
        superchainERC721.crosschainMint(_to, _tokenId);

        // Check the owner and balance of `_to` after the mint were updated correctly
        assertEq(superchainERC721.ownerOf(_tokenId), _to);
        assertEq(superchainERC721.balanceOf(_to), _toBalanceBefore + 1);
    }
}

/// @title SuperchainERC721_CrosschainBurn_Test
/// @notice Tests the `crosschainBurn` function of the `SuperchainERC721` contract.
contract SuperchainERC721_CrosschainBurn_Test is SuperchainERC721_TestInit {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event CrosschainBurn(address indexed from, uint256 indexed tokenId);

    /// @notice Tests the `crosschainBurn` function reverts when the caller is not the bridge.
    function testFuzz_crosschainBurn_callerNotBridge_reverts(address _caller, address _from, uint256 _tokenId) public {
        // Ensure the caller is not the bridge
        vm.assume(_caller != SUPERCHAIN_TOKEN_BRIDGE);

        // Expect the revert with `Unauthorized` selector
        vm.expectRevert(Unauthorized.selector);

        // Call the `crosschainBurn` function with the non-bridge caller
        vm.prank(_caller);
        superchainERC721.crosschainBurn(_from, _tokenId);
    }

    /// @notice Tests the `crosschainBurn` burns the token and emits the `CrosschainBurn` event.
    function testFuzz_crosschainBurn_succeeds(address _from, uint256 _tokenId) public {
        // Ensure `_from` is not the zero address
        vm.assume(_from != ZERO_ADDRESS);

        // Mint some tokens to `_from` so then they can be burned
        vm.prank(SUPERCHAIN_TOKEN_BRIDGE);
        superchainERC721.crosschainMint(_from, _tokenId);

        // Get the balance of `_from` before the burn to compare later on the assertions
        uint256 _fromBalanceBefore = superchainERC721.balanceOf(_from);

        // Look for the emit of the `Transfer` event
        vm.expectEmit(address(superchainERC721));
        emit Transfer(_from, ZERO_ADDRESS, _tokenId);

        // Look for the emit of the `CrosschainBurn` event
        vm.expectEmit(address(superchainERC721));
        emit CrosschainBurn(_from, _tokenId);

        // Call the `crosschainBurn` function with the bridge caller
        vm.prank(SUPERCHAIN_TOKEN_BRIDGE);
        superchainERC721.crosschainBurn(_from, _tokenId);

        // Check the balance of `_from` after the burn was updated correctly
        assertEq(superchainERC721.balanceOf(_from), _fromBalanceBefore - 1);

        // Check that the token no longer exists
        vm.expectRevert();
        superchainERC721.ownerOf(_tokenId);
    }
}
