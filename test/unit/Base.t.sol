// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import {Setup} from "test/Setup.t.sol";

contract BaseTest is Setup {
    function testDeploy() public {}

    function testNameAndSymbol() public view {
        assertEq(nft.name(), "Unrevealed Rowan' NFT", "wrong name");
        assertEq(nft.symbol(), "uROWAN", "wrong symbol");
    }

    function testOwnership() public {
        assertEq(nft.owner(), deployer, "wrong owner");
        vm.prank(deployer);
        nft.transferOwnership(user);
        assertEq(nft.owner(), deployer, "wrong owner");
        assertEq(nft.pendingOwner(), user, "wrong pendingOwner");
        vm.prank(user);
        nft.acceptOwnership();
        assertEq(nft.owner(), user, "wrong owner");
        assertEq(nft.pendingOwner(), address(0), "wrong pendingOwner");
        vm.prank(user);
        nft.renounceOwnership();
        assertEq(nft.owner(), address(0), "wrong owner");
    }

    function testInitialVariables() public view {
        assertNotEq(nft.subscriptionId(), 0, "Not set subscriptionId");
        (uint96 balance, uint64 reqCount, address owner, address[] memory consumers) = COORDINATOR.getSubscription(nft.subscriptionId());
        assertEq(balance, 0, "Already balance ??");
        assertEq(reqCount, 0, "Already Req ??");
        assertEq(owner, address(nft), "Subscription Owner");
        assertEq(consumers.length, 1, "One consumer");
        assertEq(consumers[0], address(nft), "consumer is not the nft");
    }

    function testAddFund() public {
        addFund();
    }

    function testUserPurchase() public {
        userPurchase(user);
    }
    function testRevealInCollection() public {
        startRevealInCollection();
    }
}
