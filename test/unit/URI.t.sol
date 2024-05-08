// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import {Setup} from "test/Setup.t.sol";
import "forge-std/Test.sol";
import "src/libraries/Constant.sol";

contract URITest is Setup {
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

    function testUserTokenURIBeforeFulfilledWithInCollection() public {
        userPurchase(user);
        uint tokenId = nft.tokenLength() - 1;
        startRevealInCollection();
        assertEq(
            nft.tokenURI(tokenId),
            Constant.UNREVEALED_URI,
            "wrong URIBeforeFulfilled"
        );
    }

    function testUserTokenURIAfterFulfilledWithInCollection() public {
        userPurchase(user);
        uint tokenId = nft.tokenLength() - 1;
        startRevealInCollection();
        uint requestId = nft.tokenIdToRequestId(type(uint).max);
        console.log("tid ", tokenId);
        console.log("rid ", requestId);
        mockFulFill(requestId);
        assertEq(
            nft.tokenURI(tokenId),
            Constant.UNREVEALED_URI,
            "wrong URIBeforeFulfilled"
        );
    }
}
