// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import {Setup} from "test/Setup.t.sol";

contract BaseTest is Setup {
    function testDeploy() public {}

    function testNameAndSymbolInCollection() public {
        assertEq(nft.name(), "Unrevealed Rowan's NFT", "wrong name");
        assertEq(nft.symbol(), "uROWAN", "wrong symbol");
        vm.startPrank(deployer);
        nft.startReveal();
        vm.stopPrank();
        assertEq(nft.name(), "Rowan's NFT", "wrong name");
        assertEq(nft.symbol(), "ROWAN", "wrong symbol");
    }

    function testNameAndSymbolSeperatedCollection() public {
        assertEq(nft.name(), "Unrevealed Rowan's NFT", "wrong name");
        assertEq(nft.symbol(), "uROWAN", "wrong symbol");
        vm.startPrank(deployer);
        nft.setRealNFT(address(realNFTForSeperatedCollection));
        nft.startReveal();
        vm.stopPrank();
        assertEq(nft.name(), "Unrevealed Rowan's NFT", "wrong name");
        assertEq(nft.symbol(), "uROWAN", "wrong symbol");
        assertEq(realNFTForSeperatedCollection.name(), "Rowan's NFT", "wrong name");
        assertEq(realNFTForSeperatedCollection.symbol(), "ROWAN", "wrong symbol");
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

    function testWithdrawFee() public {
        userPurchase(user);
        userPurchase(user);
        userPurchase(user);

        vm.prank(deployer);
        nft.withdrawFee();

        assertEq(deployer.balance, 3 * nft.price(), "wrong fee");
    }

    function testRetry() public {
        userPurchase(user);
        startRevealInCollection();
        vm.startPrank(deployer);
        nft.setVRFConfig(nft.keyHash(), nft.requestConfirmation(), nft.callbackGasLimit() * 100 / 10);
        nft.retryRequest(type(uint).max);
        vm.stopPrank();
    }
}
