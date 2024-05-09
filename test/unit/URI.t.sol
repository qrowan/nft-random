// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import {Setup} from "test/Setup.t.sol";
import "forge-std/Test.sol";
import "src/libraries/Constant.sol";
import {StringsUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";


contract URITest is Setup {
    using StringsUpgradeable for uint256;

    function testURIStates() public view {
        assertEq(
            nft.unrevealedURI(),
            Constant.UNREVEALED_URI,
            "wrong unrevealed URI"
        );
        assertEq(
            nft.baseURI(),
            Constant.BASE_URI,
            "wrong baseURI"
        );
    }

    function testTokenURIBeforeRevealed() public {
        userPurchase(user);
        uint tokenId = nft.tokenLength() - 1;
        assertEq(
            nft.tokenURI(tokenId),
            Constant.UNREVEALED_URI,
            "wrong URIBeforeRevealed"
        );
    }


    function testNonexistentIdURIBeforeRevealedFail() public {
        vm.expectRevert("NonexistentId");
        nft.tokenURI(0);
    }

    function testURIBeforeFulfilledWithInCollection() public {
        userPurchase(user);
        uint tokenId = nft.tokenLength() - 1;
        startRevealInCollection();
        assertEq(
            nft.tokenURI(tokenId),
            Constant.UNREVEALED_URI,
            "wrong URIBeforeFulfilled"
        );
    }

    function testURIBeforeFulfilledWithSeperatedCollection() public {
        userPurchase(user);
        uint tokenId = nft.tokenLength() - 1;
        startRevealSeperatedCollection();
        vm.prank(user);
        nft.reveal(tokenId);
        vm.expectRevert("NonexistentId");
        nft.tokenURI(tokenId);
    }

    function testLogURIAfterFulfilledWithInCollection() public {
        for (uint i; i < nft.MAX_SUPPLY(); i++) {
            userPurchase(user);
        }
        startRevealInCollection();
        uint requestId = nft.tokenIdToRequestId(type(uint).max);
        mockFulFill(requestId);
        for (uint i; i < nft.MAX_SUPPLY(); i++) {
            console.log(i, "th URI : ", nft.tokenURI(i));
        }
    }

    function testLogURIAfterFulfilledWithSeperatedCollection() public {
        for (uint i; i < nft.MAX_SUPPLY(); i++) {
            userPurchase(user);
        }
        startRevealSeperatedCollection();
        for (uint i; i < nft.MAX_SUPPLY(); i++) {
            vm.prank(user);
            nft.reveal(i);
            mockFulFill(nft.tokenIdToRequestId(i));
        }
        for (uint i; i < nft.MAX_SUPPLY(); i++) {
            console.log(i, "th URI : ", realNFTForSeperatedCollection.tokenURI(i));
        }
    }
}
