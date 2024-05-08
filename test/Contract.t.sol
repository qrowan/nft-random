// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {TestUtils} from "./TestUtils.sol";
import {StringsUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import {NFT} from "src/nft/NFT.sol";
import {RealNFTForSeperatedCollection} from "src/nft/RealNFTForSeperatedCollection.sol";
import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/vrf/interfaces/VRFCoordinatorV2Interface.sol";

import "src/libraries/Constant.sol";

contract TestContract is Test, TestUtils {
    using StringsUpgradeable for uint256;

    address public deployer;
    address public user;

    ProxyAdmin public proxyAdmin;
    NFT public nft;
    RealNFTForSeperatedCollection realNFTForSeperatedCollection;

    uint[] public userTokens;
    IERC20Metadata public LINK = IERC20Metadata(Constant.LINK);

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

    function userMint() public {
        delete userTokens;
        testMintSuccess();
        for (uint i ; i < nft.tokenLength(); i++) {
            if (nft.ownerOf(i) == user) {
                userTokens.push(i);
            }
        }
    }


    function revealInCollection() public {
        vm.prank(deployer);
        nft.startReveal();
    }

    function testOwnership() public view {
        assertEq(nft.owner(), deployer, "wrong owner");
    }

    function testNameAndSymbol() public view {
        assertEq(nft.name(), "ROWAN_NFT", "wrong name");
        assertEq(nft.symbol(), "ROWAN", "wrong symbol");
    }

    function testRevealInCollection() public {
        assertTrue(!nft.hasRevealStarted(), "hasRevealStarted before reveal");
        revealInCollection();
        assertTrue(nft.hasRevealStarted(), "hasRevealStarted after reveal");
    }

    function testMintFail() public {
        vm.deal(user, nft.price() - 1);
        vm.prank(user);
        vm.expectRevert("Not enough");
        nft.purchase{value: user.balance}(1);
    }


    function testMintSuccess() public {
        uint mintAmount = 10;
        vm.deal(user, nft.price() * mintAmount + 1);
        vm.prank(user);
        nft.purchase{value: user.balance}(mintAmount); // transferred all balance
        assertEq(user.balance, 1, "wrong user balance"); // refunded 1 as change
        assertEq(address(nft).balance, nft.price() * mintAmount, "wrong contract balance");
        assertEq(nft.balanceOf(user), mintAmount, "wrong mintAmount");
    }

//    function testMintMaxFail() public {
//        vm.deal(user, rowanNFT.price() * rowanNFT.MAX_SUPPLY() + 1);
//        vm.prank(user);
//        rowanNFT.mint{value: user.balance}(rowanNFT.MAX_SUPPLY());
//    }

    function testMintMax() public {
        vm.deal(user, nft.price() * (nft.MAX_SUPPLY() + 1));
        vm.startPrank(user);
        nft.purchase{value: user.balance}(nft.MAX_SUPPLY());
        vm.expectRevert("Cannot mint");
        nft.purchase{value: user.balance}(1);
        vm.stopPrank();

    }

    function testBaseAndDefaultURI() public view {
        assertEq(
            nft.unrevealedURI(),
            "https://openseacreatures.io/",
            "wrong defaultURI"
        );
        assertEq(
            nft.baseURI(),
            "https://storage.googleapis.com/opensea-prod.appspot.com/puffs/",
            "wrong baseURI"
        );
    }

    function testNonexistentIdURIBeforeRevealedFail() public {
        vm.expectRevert();
        nft.tokenURI(0);
    }

    function testUserTokenURIBeforeRevealed() public {
        userMint();
        for (uint i; i < userTokens.length; i++) {
            uint tokenId = userTokens[i];
            assertEq(
                nft.tokenURI(tokenId),
                string(abi.encodePacked("https://openseacreatures.io/", tokenId.toString())),
                "wrong unrevealed URI"
            );
            console.log("unrevealed URI : ", nft.tokenURI(tokenId));
        }
    }

    function testNonexistentIdURIAfterRevealedFail() public {
        revealInCollection();
        vm.expectRevert();
        nft.tokenURI(0);
    }

    function testUserTokenURIAfterRevealed() public {
        userMint();
        revealInCollection();
        for (uint i; i < userTokens.length; i++) {
            uint tokenId = userTokens[i];
            console.log("revealed URI : ", nft.tokenURI(tokenId));
            assertEq(
                nft.tokenURI(tokenId),
                string(abi.encodePacked("https://storage.googleapis.com/opensea-prod.appspot.com/puffs/", tokenId.toString(), ".png")),
                "wrong revealed URI"
            );
        }
    }

    function testLogSubscriptionId() public view {
        console.log("Subscription ID ", nft.subscriptionId());
    }
}
