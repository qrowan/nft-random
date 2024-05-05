// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";

contract RowanNFT is ERC721Upgradeable, Ownable2StepUpgradeable {
    using StringsUpgradeable for uint256;

    string public defaultURI;
    string public baseURI;
    string public baseExtension = ".json";
    uint public price; // price for 1 NFT
    bool public revealed = false;
    uint public tokenLength = 0;

    error NonexistentId(uint tokenId);

    function initialize() public initializer {
        __ERC721_init("ROWAN_NFT" , "ROWAN");
        __Ownable2Step_init();

        // TODO : fix URI
        baseURI = "https://storage.googleapis.com/opensea-prod.appspot.com/puffs/3.png";
        defaultURI = "https://openseacreatures.io/3";
        price = 0.00001 ether;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) {
            revert NonexistentId({tokenId: tokenId});
        }
        if (!revealed) return defaultURI;

        // TODO : fix URI
        return bytes(baseURI).length > 0
            ? string(abi.encodePacked(baseURI/*, tokenId.toString(), baseExtension*/))
            : "";
    }

    function reveal() external onlyOwner {
        revealed = true;
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
}
