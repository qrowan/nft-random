// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {TestUtils} from "./TestUtils.sol";
import {StringsUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import {NFT} from "src/nft/NFT.sol";
import {RealNFTForSeperatedCollection} from "src/nft/RealNFTForSeperatedCollection.sol";
import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/vrf/interfaces/VRFCoordinatorV2Interface.sol";
import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/shared/interfaces/LinkTokenInterface.sol";

import "src/libraries/Constant.sol";

contract Setup is Test, TestUtils {
    using StringsUpgradeable for uint256;

    address public deployer;
    address public user;

    ProxyAdmin public proxyAdmin;
    NFT public nft;
    RealNFTForSeperatedCollection realNFTForSeperatedCollection;

    uint[] public userTokens;
    VRFCoordinatorV2Interface public COORDINATOR = VRFCoordinatorV2Interface(Constant.VRF_COORDINATOR);
    LinkTokenInterface public LINK = LinkTokenInterface(Constant.LINK);

    error NonexistentId(uint);

    function setUp() public {
        deployer = address(0x1234);
        user = address(0x1235);
        deal(address(LINK), deployer, 100 ether);

        vm.startPrank(deployer);
        {
            proxyAdmin = new ProxyAdmin();
            LINK.transfer(address(proxyAdmin), 100 ether);
            NFT _nft = new NFT();
            nft = NFT(_makeBeaconProxy(proxyAdmin, address(_nft)));
            RealNFTForSeperatedCollection _realNFT = new RealNFTForSeperatedCollection();
            realNFTForSeperatedCollection = RealNFTForSeperatedCollection(
                _makeBeaconProxy(proxyAdmin, address(_realNFT))
            );

            nft.initialize();
            realNFTForSeperatedCollection.initialize(address(nft));
        }
        vm.stopPrank();
    }

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

    function addFund() internal {
        uint amount = 100 ether;
        deal(address(LINK), deployer, amount);
        assertEq(LINK.balanceOf(deployer), amount, "deal fail");
        vm.startPrank(deployer);
        LINK.approve(address(nft), amount);
        assertEq(LINK.allowance(deployer, address(nft)), amount, "deal fail");
        nft.addFund(amount);
        vm.stopPrank();
        assertEq(LINK.balanceOf(deployer), 0, "Why still have LINK ?");
        assertEq(nft.linkBalance(), amount, "LINK balance is strange");
    }

    function testAddFund() public {
        addFund();
    }

//
//    function revealInCollection() public {
//        vm.prank(deployer);
//        nft.startReveal();
//    }
//
//
//    function testRevealInCollection() public {
//        assertTrue(!nft.hasRevealStarted(), "hasRevealStarted before reveal");
//        revealInCollection();
//        assertTrue(nft.hasRevealStarted(), "hasRevealStarted after reveal");
//    }
//
//
//
////    function testPurchaseMaxFail() public {
////        vm.deal(user, rowanNFT.price() * rowanNFT.MAX_SUPPLY() + 1);
////        vm.prank(user);
////        rowanNFT.mint{value: user.balance}(rowanNFT.MAX_SUPPLY());
////    }
//
//
//    function testBaseAndDefaultURI() public view {
//        assertEq(
//            nft.unrevealedURI(),
//            "https://openseacreatures.io/",
//            "wrong defaultURI"
//        );
//        assertEq(
//            nft.baseURI(),
//            "https://storage.googleapis.com/opensea-prod.appspot.com/puffs/",
//            "wrong baseURI"
//        );
//    }
//
//    function testNonexistentIdURIBeforeRevealedFail() public {
//        vm.expectRevert();
//        nft.tokenURI(0);
//    }
//
//    function testUserTokenURIBeforeRevealed() public {
//        userMint();
//        for (uint i; i < userTokens.length; i++) {
//            uint tokenId = userTokens[i];
//            assertEq(
//                nft.tokenURI(tokenId),
//                string(abi.encodePacked("https://openseacreatures.io/", tokenId.toString())),
//                "wrong unrevealed URI"
//            );
//            console.log("unrevealed URI : ", nft.tokenURI(tokenId));
//        }
//    }
//
//    function testNonexistentIdURIAfterRevealedFail() public {
//        revealInCollection();
//        vm.expectRevert();
//        nft.tokenURI(0);
//    }
//
//    function testUserTokenURIAfterRevealed() public {
//        userMint();
//        revealInCollection();
//        for (uint i; i < userTokens.length; i++) {
//            uint tokenId = userTokens[i];
//            console.log("revealed URI : ", nft.tokenURI(tokenId));
//            assertEq(
//                nft.tokenURI(tokenId),
//                string(abi.encodePacked("https://storage.googleapis.com/opensea-prod.appspot.com/puffs/", tokenId.toString(), ".png")),
//                "wrong revealed URI"
//            );
//        }
//    }
//
//    function testLogSubscriptionId() public view {
//        console.log("Subscription ID ", nft.subscriptionId());
//    }
}
