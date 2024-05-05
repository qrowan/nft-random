// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "../chainlink_libraries/VRFConsumerBaseV2Upgradeable.sol";
import "../libraries/Constant.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";

import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/vrf/interfaces/VRFCoordinatorV2Interface.sol";
import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/shared/interfaces/LinkTokenInterface.sol";

contract RowanNFT is ERC721Upgradeable, Ownable2StepUpgradeable, VRFConsumerBaseV2Upgradeable {
    using StringsUpgradeable for uint256;

    uint public price; // price for 1 NFT
    string public defaultURI;
    string public baseURI;
    bool public revealed;

    uint public tokenLength;
    uint public constant MAX_SUPPLY = 20;

    VRFCoordinatorV2Interface public COORDINATOR;
    LinkTokenInterface public LINK;

    uint64 public s_subscriptionId;
    uint requestId;
    uint public requestStatus = 0; // 0: not requested, 1: requested, 2: fulfilled
    uint256[] randomWords;


    error NonexistentId(uint tokenId);

    function initialize() public initializer {
        __ERC721_init("ROWAN_NFT" , "ROWAN");
        __Ownable2Step_init();
        __VRFConsumerBaseV2_init(address(COORDINATOR));

        // TODO : fix URI
        baseURI = Constant.BASE_URI;
        defaultURI = Constant.DEFAULT_URI;
        price = 0.00001 ether;
        COORDINATOR = VRFCoordinatorV2Interface(Constant.VRF_COORDINATOR);
        LinkTokenInterface(Constant.LINK);

        s_subscriptionId = COORDINATOR.createSubscription();
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) {
            revert NonexistentId({tokenId: tokenId});
        }
        if (!revealed) return bytes(defaultURI).length > 0
        ? string(abi.encodePacked(defaultURI, tokenId.toString()))
            : "";

        // TODO : fix URI
        return bytes(baseURI).length > 0
            ? string(abi.encodePacked(baseURI, tokenId.toString(), ".png"))
            : "";
    }

    function reveal() external onlyOwner {
        revealed = true;
    }

    function convert(uint tokenId) internal returns (uint) {
        if (!revealed) return 0;
        return randomWords[tokenId] % 25;
    }

    // purchase NFT
    function mint(uint _mintAmount) public payable {
        uint pay = price * _mintAmount;
        require(msg.value >= pay, "Not enough");
        require(tokenLength < MAX_SUPPLY, "Cannot mint");

        for (uint i; i < _mintAmount; i++) {
            _safeMint(msg.sender, tokenLength);
            tokenLength++;
        }
        if (msg.value > pay) {
            payable(msg.sender).transfer(msg.value - pay);
        }
    }

    // Assumes the subscription is funded sufficiently.
    function requestRandomWords()
    external
    onlyOwner
    {
        require(requestStatus == 0, "Already requested");

        // Will revert if subscription is not set and funded.
        uint _requestId = COORDINATOR.requestRandomWords(
            Constant.KEY_HASH,
            s_subscriptionId,
            Constant.REQUEST_CONFIRMATIONS,
            Constant.CALL_BACK_GAS_LIMIT,
            uint32(MAX_SUPPLY)
        );
        requestStatus = 1;
        requestId = _requestId;

        // TODO : delete after finishing VRF
        {
            uint[] memory _randomWords = new uint[](25);
            for (uint i; i < 25; i++) {
                _randomWords[i] = i;
            }
            randomWords = _randomWords;
        }
    }

    function fulfillRandomWords(
        uint256 /*_requestId*/, uint256[] memory _randomWords
    ) internal override {
        require(requestStatus == 1, "Not requested or already fulfilled");
        randomWords = _randomWords;
        requestStatus = 2;
    }
}
