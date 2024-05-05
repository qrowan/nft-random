// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";

contract RowanNFT is ERC721Upgradeable, Ownable2StepUpgradeable {
    function initialize() public initializer {
        __ERC721_init("ROWAN_NFT" , "ROWAN");
        __Ownable2Step_init();
    }
}
