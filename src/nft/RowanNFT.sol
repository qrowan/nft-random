// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import "../chainlink_libraries/VRFConsumerBaseV2Upgradeable.sol";
import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/vrf/interfaces/VRFCoordinatorV2Interface.sol";

contract RowanNFT is ERC721Upgradeable, Ownable2StepUpgradeable, VRFConsumerBaseV2Upgradeable {
    using StringsUpgradeable for uint256;

    string public defaultURI;
    string public baseURI;
    uint public price; // price for 1 NFT
    bool public revealed = false;
    uint public tokenLength = 0;
    VRFCoordinatorV2Interface public constant COORDINATOR = VRFCoordinatorV2Interface(0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625);

    error NonexistentId(uint tokenId);

    function initialize() public initializer {
        __ERC721_init("ROWAN_NFT" , "ROWAN");
        __Ownable2Step_init();
        __VRFConsumerBaseV2_init(address(COORDINATOR));

        // TODO : fix URI
        baseURI = "https://storage.googleapis.com/opensea-prod.appspot.com/puffs/";
        defaultURI = "https://openseacreatures.io/";
        price = 0.00001 ether;
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
        return tokenId;
    }

    // purchase NFT
    function mint(uint _mintAmount) public payable {
        uint pay = price * _mintAmount;
        require(msg.value >= pay, "Not enough");
        for (uint i; i < _mintAmount; i++) {
            _safeMint(msg.sender, tokenLength);
            tokenLength++;
        }
        if (msg.value > pay) {
            payable(msg.sender).transfer(msg.value - pay);
        }
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {

    }
}
