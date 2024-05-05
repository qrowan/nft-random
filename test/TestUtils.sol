// SPDX-License-address constant Identifier = UNLICENSE;
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract TestUtils is Test {
    uint256 internal _setupSnapshotId;

    function _makeBeaconProxy(
        ProxyAdmin _proxyAdmin,
        address _implementation
    ) internal returns (address payable) {
        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(address(_implementation), address(_proxyAdmin), new bytes(0));

        return payable(address(proxy));
    }
}

