// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import {Setup} from "test/Setup.t.sol";

contract PurchaseTest is Setup {
    function testPurchaseOnce() public {
        uint mintAmount = 1;
        vm.deal(user, nft.price() * mintAmount + 1);
        vm.prank(user);
        nft.purchase{value: user.balance}(mintAmount); // transferred all balance
        assertEq(user.balance, 1, "wrong user balance"); // refunded 1 as change
        assertEq(address(nft).balance, nft.price() * mintAmount, "wrong contract balance");
        assertEq(nft.balanceOf(user), mintAmount, "wrong mintAmount");
    }

    function testPurchaseMulti() public {
        uint mintAmount = 2;
        vm.deal(user, nft.price() * mintAmount + 10);
        vm.prank(user);
        nft.purchase{value: user.balance}(mintAmount); // transferred all balance
        assertEq(user.balance, 10, "wrong user balance"); // refunded 1 as change
        assertEq(address(nft).balance, nft.price() * mintAmount, "wrong contract balance");
        assertEq(nft.balanceOf(user), mintAmount, "wrong mintAmount");
    }

    function testPurchaseMax() public {
        vm.deal(user, nft.price() * nft.MAX_SUPPLY() + 1);
        vm.startPrank(user);
        nft.purchase{value: user.balance}(nft.MAX_SUPPLY());
        assertEq(user.balance, 1, "wrong user balance"); // refunded 1 as change
        assertEq(address(nft).balance, nft.price() * nft.MAX_SUPPLY(), "wrong contract balance");
        assertEq(nft.balanceOf(user), nft.MAX_SUPPLY(), "wrong mintAmount");

    }

    function testPurchaseNotEnoughFail() public {
        vm.deal(user, nft.price() - 1);
        vm.prank(user);
        vm.expectRevert("Not enough");
        nft.purchase{value: user.balance}(1);
    }

    function testPurchaseCannotMintFail() public {
        vm.deal(user, nft.price() * (nft.MAX_SUPPLY() + 1));
        vm.startPrank(user);
        nft.purchase{value: user.balance}(nft.MAX_SUPPLY());
        vm.expectRevert("Cannot mint");
        nft.purchase{value: user.balance}(1);
        vm.stopPrank();
    }

    function testPurchaseAlreadyRevealStartedFail() public {
        vm.prank(deployer);
        nft.startReveal();
        vm.deal(user, nft.price());
        vm.startPrank(user);
        vm.expectRevert("Already reveal started");
        nft.purchase{value: user.balance}(1);
        vm.stopPrank();
    }
}
