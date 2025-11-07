// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

// Testing utilities
import { Test } from "forge-std/Test.sol";

// Libraries
import { Predeploys } from "src/libraries/Predeploys.sol";

// Target contract
import { SuperchainERC721 } from "src/L2/SuperchainERC721.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { ERC721 } from "@solady-v0.0.245/tokens/ERC721.sol";
import { ISuperchainERC721 } from "interfaces/L2/ISuperchainERC721.sol";
import { MockSuperchainERC721Implementation } from "test/mocks/SuperchainERC721Implementation.sol";
import { Unauthorized } from "src/libraries/errors/CommonErrors.sol";
import { IL2ToL2CrossDomainMessenger } from "interfaces/L2/IL2ToL2CrossDomainMessenger.sol";

/// @title SuperchainERC721_TestInit
/// @notice Reusable test initialization for `SuperchainERC721` tests.
abstract contract SuperchainERC721_TestInit is Test {
    address internal constant ZERO_ADDRESS = address(0);
    address internal constant MESSENGER = Predeploys.L2_TO_L2_CROSS_DOMAIN_MESSENGER;

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

/// @title SuperchainERC721_CrosschainTransferInitiated_Test
/// @notice Tests the `crosschainTransferInitiated` function of the `SuperchainERC721` contract.
contract SuperchainERC721_CrosschainTransferInitiated_Test is SuperchainERC721_TestInit {
    /// @notice Tests the `crosschainTransferInitiated` function reverts when the caller is not the owner or approved
    /// operator of the token.
    function testFuzz_crosschainTransferInitiated_callerNotOwnerOrApprovedOperator_reverts(
        address _from,
        address _to,
        uint256 _tokenId,
        uint256 _destinationChainId
    )
        public
    {
        vm.assume(_from != address(1));
        superchainERC721.mint(address(1), _tokenId);

        vm.prank(_from);
        vm.expectRevert(Unauthorized.selector);
        superchainERC721.initiateCrosschainTransfer(_from, _to, _tokenId, _destinationChainId);
    }

    /// @notice Tests the `crosschainTransferInitiated` function succeeds.
    function testFuzz_crosschainTransferInitiated_succeeds(
        address _from,
        address _to,
        uint256 _tokenId,
        uint256 _destinationChainId
    )
        public
    {
        superchainERC721.mint(_from, _tokenId);

        // Expect the emit of the `CrosschainTransferInitiated` event
        vm.expectEmit(address(superchainERC721));
        emit ISuperchainERC721.CrosschainTransferInitiated(_from, _to, _tokenId, _destinationChainId, bytes32(0));

        // Expect a call to the messenger
        _mockAndExpect(
            address(MESSENGER),
            abi.encodeCall(
                IL2ToL2CrossDomainMessenger.sendMessage,
                (
                    _destinationChainId,
                    address(superchainERC721),
                    abi.encodeCall(superchainERC721.finalizeCrosschainTransfer, (_to, _tokenId))
                )
            ),
            abi.encode(bytes32(0))
        );

        vm.prank(_from);
        superchainERC721.initiateCrosschainTransfer(_from, _to, _tokenId, _destinationChainId);

        // Check the token is burned
        vm.expectRevert(ERC721.TokenDoesNotExist.selector);
        assertEq(superchainERC721.ownerOf(_tokenId), address(0));
    }
}

contract SuperchainERC721_CrosschainTransferFinalized_Test is SuperchainERC721_TestInit {
    /// @notice Tests the `crosschainTransferFinalized` function reverts when the caller is not the
    /// L2ToL2CrossDomainMessenger.
    function testFuzz_crosschainTransferFinalized_callerNotMessenger_reverts() public { }

    /// @notice Tests the `crosschainTransferFinalized` function reverts when the sender of the message is not the
    /// contract.
    function testFuzz_crosschainTransferFinalized_senderNotContract_reverts() public { }

    /// @notice Tests the `crosschainTransferFinalized` function succeeds.
    function testFuzz_crosschainTransferFinalized_succeeds(address _to, uint256 _tokenId) public { }
}
