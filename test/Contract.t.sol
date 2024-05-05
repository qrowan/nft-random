// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import {RowanNFT} from "../src/nft/RowanNFT.sol";
import "forge-std/Test.sol";
import {TestUtils} from "./TestUtils.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {StringsUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

contract TestContract is Test, TestUtils {
    using StringsUpgradeable for uint256;

    address deployer;
    address user;
    RowanNFT rowanNFT;
    ProxyAdmin proxyAdmin;
    uint[] userTokens;
    error NonexistentId(uint);


    function setUp() public {
        deployer = address(0x1234);
        user = address(0x1235);

        vm.startPrank(deployer);
        {
            proxyAdmin = new ProxyAdmin();
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
        vm.deal(user, rowanNFT.price() -1);
        vm.prank(user);
        vm.expectRevert("Not enough");
        rowanNFT.mint(1);
    }

    function testMintSuccess() public {
        uint mintAmount = 10;
        vm.deal(user, rowanNFT.price() * mintAmount + 1);
        vm.prank(user);
        rowanNFT.mint{value: user.balance}(mintAmount);
        assertEq(user.balance, 1, "wrong user balance");
        assertEq(address(rowanNFT).balance, rowanNFT.price() * mintAmount, "wrong contract balance");
        assertEq(rowanNFT.balanceOf(user), mintAmount, "wrong mintAmount");
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
        uint tokenId = userTokens[0];
        assertEq(
            rowanNFT.tokenURI(tokenId),
            string(abi.encodePacked("https://openseacreatures.io/", tokenId.toString())),
            "wrong unrevealed URI"
        );
        console.log("unrevealed URI : ", rowanNFT.tokenURI(tokenId));
    }

    function testNonexistentIdURIAfterRevealedFail() public {
        reveal();
        vm.expectRevert();
        rowanNFT.tokenURI(0);
    }

    function testUserTokenURIAfterRevealed() public {
        userMint();
        reveal();
        uint tokenId = userTokens[0];
        console.log("revealed URI : ", rowanNFT.tokenURI(tokenId));
        assertEq(
            rowanNFT.tokenURI(tokenId),
            string(abi.encodePacked("https://storage.googleapis.com/opensea-prod.appspot.com/puffs/", tokenId.toString(), ".png")),
            "wrong revealed URI"
        );
    }

}
