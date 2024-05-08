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

    function userPurchase(address _user) internal {
        vm.deal(_user, nft.price());
        vm.startPrank(_user);
        nft.purchase{value: user.balance}(1);
        vm.stopPrank();
    }


    function startRevealInCollection() public {
        vm.prank(deployer);
        nft.startReveal();
    }

    function mockFulFill(uint requestId) public {
        NFT.RequestStatus status = nft.requestStatus(type(uint).max);
        uint MAX_SUPPLY = nft.MAX_SUPPLY();
        require(status == NFT.RequestStatus.Requested, "not requested");
        uint256[] memory _randomWords = new uint256[](MAX_SUPPLY);
        for (uint i; i < _randomWords.length; i++) {
            _randomWords[i] = i;
        }
        vm.prank(address(COORDINATOR));
        nft.rawFulfillRandomWords(requestId, _randomWords);
    }
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
//    function testLogSubscriptionId() public view {
//        console.log("Subscription ID ", nft.subscriptionId());
//    }
}
