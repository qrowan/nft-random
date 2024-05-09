// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {TestUtils} from "test/TestUtils.sol";
import {StringsUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import {NFT} from "src/nft/NFT.sol";
import {RealNFTForSeperatedCollection} from "src/nft/RealNFTForSeperatedCollection.sol";
import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/vrf/interfaces/VRFCoordinatorV2Interface.sol";
import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/shared/interfaces/LinkTokenInterface.sol";

import "src/libraries/Constant.sol";

contract Deployed is Test, TestUtils {
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
        deployer = address(Constant.DEPLOYER);
        user = address(0x1235);

        vm.startPrank(deployer);
        {
            proxyAdmin = ProxyAdmin(Constant.PROXY_ADMIN);
            nft = NFT(Constant.NFT);
            realNFTForSeperatedCollection = RealNFTForSeperatedCollection(Constant.REAL_NFT_FOR_SEPERATED_COLLECTION);
        }
        vm.stopPrank();
    }

    function testShowLiveData() public {
        console.log("Contract addresses");
        console.log("NFT                           : ", address(nft));
        console.log("realNFTForSeperatedCollection : ", address(realNFTForSeperatedCollection));
        console.log("NFT(used) name   : ", nft.name());
        console.log("Real NFT  name   : ", realNFTForSeperatedCollection.name());
        console.log("NFT(used) symbol : ", nft.symbol());
        console.log("Real NFT  symbol : ", realNFTForSeperatedCollection.symbol());

        console.log("Chosen Strategy : ", uint(nft.strategy()));
        console.log("=> 0 means In-Collection strategy");
        console.log("=> 1 means Seperated-Collection strategy");

        console.log("NFT Info");
        for(uint i; i < 5; i++) {
            console.log("tokenId : ", i);
//            console.log("owner   : ", realNFTForSeperatedCollection.ownerOf(i));
            console.log("URI     : ", realNFTForSeperatedCollection.tokenURI(i));
        }
    }

}
