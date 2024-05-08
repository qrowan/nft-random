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

/// @dev See the Solidity Scripting tutorial: https://book.getfoundry.sh/tutorials/solidity-scripting
contract Deploy is TestUtils {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        ProxyAdmin proxyAdmin = new ProxyAdmin();
        NFT _nft = new NFT();
        NFT nft = NFT(_makeBeaconProxy(proxyAdmin, address(_nft)));
        nft.initialize();
        vm.stopBroadcast();
    }
}
