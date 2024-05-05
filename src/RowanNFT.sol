// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";

contract RowanNFT is ERC721Upgradeable, Ownable2StepUpgradeable {
    uint public price; // price for 1 NFT
    uint public tokenLength = 0;

    function initialize() public initializer {
        __ERC721_init("ROWAN_NFT" , "ROWAN");
        __Ownable2Step_init();
        price = 0.00001 ether;
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
