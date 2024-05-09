// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/vrf/interfaces/VRFCoordinatorV2Interface.sol";
import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/shared/interfaces/LinkTokenInterface.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

import {NFT} from "src/nft/NFT.sol";
import {RealNFTForSeperatedCollection} from "src/nft/RealNFTForSeperatedCollection.sol";

import "src/libraries/Constant.sol";

import { BaseScript } from "./Base.s.sol";
import {TestUtils} from "../test/TestUtils.sol";
import "forge-std/Test.sol";

/// @dev See the Solidity Scripting tutorial: https://book.getfoundry.sh/tutorials/solidity-scripting
contract Purchase is TestUtils {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        NFT nft = NFT(Constant.NFT);
        nft.purchase{value: nft.price()* 5}(5);

        vm.stopBroadcast();
    }
}

contract StartReveal is TestUtils {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        NFT nft = NFT(Constant.NFT);
        RealNFTForSeperatedCollection realNft = RealNFTForSeperatedCollection(Constant.REAL_NFT_FOR_SEPERATED_COLLECTION);
        nft.setRealNFT(address(realNft));
        nft.startReveal();
        vm.stopBroadcast();
    }
}

contract Reveal is TestUtils {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        NFT nft = NFT(Constant.NFT);
        for (uint i; i < 5; i++) {
            nft.reveal(i);
        }
        vm.stopBroadcast();
    }
}

contract Retry is TestUtils {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        NFT nft = NFT(Constant.NFT);
        nft.setVRFConfig(nft.keyHash(), nft.requestConfirmation(), nft.callbackGasLimit() * 100 / 10);
        nft.retryRequest(0);
        nft.retryRequest(1);
        nft.retryRequest(2);
        nft.retryRequest(3);
        nft.retryRequest(4);
        vm.stopBroadcast();
    }
}

