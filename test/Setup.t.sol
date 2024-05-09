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
            RealNFTForSeperatedCollection _realNft = new RealNFTForSeperatedCollection();
            realNFTForSeperatedCollection = RealNFTForSeperatedCollection(
                _makeBeaconProxy(proxyAdmin, address(_realNft))
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


    function startRevealInCollection() internal {
        vm.prank(deployer);
        nft.startReveal();
    }

    function startRevealSeperatedCollection() internal {
        vm.startPrank(deployer);
        nft.setRealNFT(address(realNFTForSeperatedCollection));
        nft.startReveal();
        vm.stopPrank();
    }

    // @dev only for test. For real, chainlink calls rawFulfillRandomWords
    function mockFulFill(uint requestId) internal {
        uint tokenId = nft.requestIdToTokenId(requestId);
        NFT.RequestStatus status = nft.requestStatus(tokenId);
        require(status == NFT.RequestStatus.Requested, "not requested");

        if (uint(nft.strategy()) == 0) { // RevealStrategy.InCollection
            uint MAX_SUPPLY = nft.MAX_SUPPLY();
            uint256[] memory _randomWords = new uint256[](MAX_SUPPLY);
            for (uint i; i < _randomWords.length; i++) {
                _randomWords[i] =  uint(keccak256(abi.encode(i + block.timestamp)));
            }
            vm.prank(address(COORDINATOR));
            nft.rawFulfillRandomWords(requestId, _randomWords);
        } else { // RevealStrategy.SeperatedCollection
            uint256[] memory _randomWords = new uint256[](1);
            _randomWords[0] =  uint(keccak256(abi.encode(tokenId + block.timestamp)));
            vm.prank(address(COORDINATOR));
            nft.rawFulfillRandomWords(requestId, _randomWords);
        }
    }

    function convert(uint a) internal pure returns (uint) {
        return a % 25;
    }
}
