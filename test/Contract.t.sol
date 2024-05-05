// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import {RowanNFT} from "../src/nft/RowanNFT.sol";
import "forge-std/Test.sol";
import {TestUtils} from "./TestUtils.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {StringsUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "src/libraries/Constant.sol";
import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/vrf/interfaces/VRFCoordinatorV2Interface.sol";

contract TestContract is Test, TestUtils {
    using StringsUpgradeable for uint256;

    address deployer;
    address user;
    RowanNFT rowanNFT;
    ProxyAdmin proxyAdmin;
    uint[] userTokens;
    error NonexistentId(uint);
    IERC20Metadata LINK = IERC20Metadata(Constant.LINK);


    function setUp() public {
        deployer = address(0x1234);
        user = address(0x1235);
        deal(address(LINK), deployer, 100 ether);

        vm.startPrank(deployer);
        {
            proxyAdmin = new ProxyAdmin();
            LINK.transfer(address(proxyAdmin), 100 ether);
            RowanNFT _rowanNFT = new RowanNFT();
            rowanNFT = RowanNFT(_makeBeaconProxy(proxyAdmin, address(_rowanNFT)));
            rowanNFT.initialize();
        }
        vm.stopPrank();
    }

    function userMint() public {
        delete userTokens;
        testMintSuccess();
        for (uint i ; i < rowanNFT.tokenLength(); i++) {
            if (rowanNFT.ownerOf(i) == user) {
                userTokens.push(i);
            }
        }
    }

    function reveal() public {
        vm.prank(deployer);
        rowanNFT.reveal();
    }

    function testOwnership() public {
        assertEq(rowanNFT.owner(), deployer, "wrong owner");
    }

    function testNameAndSymbol() public {
        assertEq(rowanNFT.name(), "ROWAN_NFT", "wrong name");
        assertEq(rowanNFT.symbol(), "ROWAN", "wrong symbol");
    }

    function testReveal() public {
        assertTrue(!rowanNFT.revealed(), "revealed before reveal");
        reveal();
        assertTrue(rowanNFT.revealed(), "revealed after reveal");
    }

    function testMintFail() public {
        vm.deal(user, rowanNFT.price() - 1);
        vm.prank(user);
        vm.expectRevert("Not enough");
        rowanNFT.mint{value: user.balance}(1);
    }


    function testMintSuccess() public {
        uint mintAmount = 10;
        vm.deal(user, rowanNFT.price() * mintAmount + 1);
        vm.prank(user);
        rowanNFT.mint{value: user.balance}(mintAmount); // transferred all balance
        assertEq(user.balance, 1, "wrong user balance"); // refunded 1 as change
        assertEq(address(rowanNFT).balance, rowanNFT.price() * mintAmount, "wrong contract balance");
        assertEq(rowanNFT.balanceOf(user), mintAmount, "wrong mintAmount");
    }

//    function testMintMaxFail() public {
//        vm.deal(user, rowanNFT.price() * rowanNFT.MAX_SUPPLY() + 1);
//        vm.prank(user);
//        rowanNFT.mint{value: user.balance}(rowanNFT.MAX_SUPPLY());
//    }

    function testMintMax() public {
        vm.deal(user, rowanNFT.price() * (rowanNFT.MAX_SUPPLY() + 1));
        vm.startPrank(user);
        rowanNFT.mint{value: user.balance}(rowanNFT.MAX_SUPPLY());
        vm.expectRevert("Cannot mint");
        rowanNFT.mint{value: user.balance}(1);
        vm.stopPrank();

    }

    function testBaseAndDefaultURI() public {
        assertEq(
            rowanNFT.defaultURI(),
            "https://openseacreatures.io/",
            "wrong defaultURI"
        );
        assertEq(
            rowanNFT.baseURI(),
            "https://storage.googleapis.com/opensea-prod.appspot.com/puffs/",
            "wrong baseURI"
        );
    }

    function testNonexistentIdURIBeforeRevealedFail() public {
        vm.expectRevert();
        rowanNFT.tokenURI(0);
    }

    function testUserTokenURIBeforeRevealed() public {
        userMint();
        for (uint i; i < userTokens.length; i++) {
            uint tokenId = userTokens[i];
            assertEq(
                rowanNFT.tokenURI(tokenId),
                string(abi.encodePacked("https://openseacreatures.io/", tokenId.toString())),
                "wrong unrevealed URI"
            );
            console.log("unrevealed URI : ", rowanNFT.tokenURI(tokenId));
        }
    }

    function testNonexistentIdURIAfterRevealedFail() public {
        reveal();
        vm.expectRevert();
        rowanNFT.tokenURI(0);
    }

    function testUserTokenURIAfterRevealed() public {
        userMint();
        reveal();
        for (uint i; i < userTokens.length; i++) {
            uint tokenId = userTokens[i];
            console.log("revealed URI : ", rowanNFT.tokenURI(tokenId));
            assertEq(
                rowanNFT.tokenURI(tokenId),
                string(abi.encodePacked("https://storage.googleapis.com/opensea-prod.appspot.com/puffs/", tokenId.toString(), ".png")),
                "wrong revealed URI"
            );
        }
    }

    function testLogSubscriptionId() public {
        console.log("Subscription ID ", rowanNFT.s_subscriptionId());
    }

    function testVRF() public {
        // TODO : test about VRF after deploy
    }

}
