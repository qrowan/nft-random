// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import {RowanNFT} from "src/RowanNFT.sol";
import {TestUtils} from "./TestUtils.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract TestContract is TestUtils {
    address deployer;
    RowanNFT rowanNFT;
    ProxyAdmin proxyAdmin;

    function setUp() public {
        deployer = address(0x1234);
        vm.startPrank(deployer);
        {
            proxyAdmin = new ProxyAdmin();
            RowanNFT _rowanNFT = new RowanNFT();
            rowanNFT = RowanNFT(_makeBeaconProxy(proxyAdmin, address(_rowanNFT)));
            rowanNFT.initialize();
        }
        vm.stopPrank();
    }

    function testBar() public {
        assertEq(uint256(1), uint256(1), "ok");
    }

    function testFoo(uint256 x) public {
        vm.assume(x < type(uint128).max);
        assertEq(x + x, x * 2);
    }

    function testOwnership() public {
        assertEq(rowanNFT.owner(), deployer, "wrong owner");
    }

    function testNameAndSymbol() public {
        assertEq(rowanNFT.name(), "ROWAN_NFT", "wrong name");
        assertEq(rowanNFT.symbol(), "ROWAN", "wrong symbol");
    }
}
