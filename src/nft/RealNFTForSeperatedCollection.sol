// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "../libraries/Constant.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";

contract RealNFTForSeperatedCollection is ERC721Upgradeable, Ownable2StepUpgradeable {
    using StringsUpgradeable for uint256;

    string public baseURI;
    address public unrevealedNFT;
    mapping(uint => uint) public words;

    /* MODIFIERS */
    modifier onlyUnrevealedNFT() {
        require(msg.sender == unrevealedNFT, "Only Unrevealed NFT");
        _;
    }

    /* INITIALIZE */
    function initialize(address _unrevealedNFT) external initializer {
        // init inherited contracts
        __ERC721_init("Rowan's NFT" , "ROWAN");
        __Ownable2Step_init();

        // set variables
        baseURI = Constant.BASE_URI;
        unrevealedNFT = _unrevealedNFT;
    }

    /* RESTRICTED FUNCTIONS */
    function mint(uint _tokenId, uint _word) external onlyUnrevealedNFT {
        require(!_exists(_tokenId), "Already existId");
        _mint(msg.sender, _tokenId);
        words[_tokenId] = _word;
    }

    /* VIEW FUNCTIONS */
    function tokenURI(uint _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "NonexistentId");

        return bytes(baseURI).length > 0
            ? string(abi.encodePacked(baseURI, words[_tokenId].toString(), ".png"))
            : "";
    }

    /* INTERNAL FUNCTIONS */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
}
