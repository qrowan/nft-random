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

    error NonexistentId(uint tokenId);

    modifier onlyUnrevealedNFT() {
        require(msg.sender == unrevealedNFT, "Only Unrevealed NFT");
        _;
    }

    /* INITIALIZE */
    function initialize(address _unrevealedNFT) public initializer {
        // init inherited contracts
        __ERC721_init("Rowan's NFT" , "ROWAN");
        __Ownable2Step_init();

        // set variables
        baseURI = Constant.BASE_URI;
        unrevealedNFT = _unrevealedNFT;
    }

    /* RESTRICTED FUNCTIONS */
    function mint(uint tokenId, uint word) public onlyUnrevealedNFT {
        require(!_exists(tokenId), "Already existId");
        _safeMint(msg.sender, tokenId);
        words[tokenId] = word;
    }

    /* VIEW FUNCTIONS */
    function tokenURI(uint tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) {
            revert NonexistentId({tokenId: tokenId});
        }

        return bytes(baseURI).length > 0
            ? string(abi.encodePacked(baseURI, words[tokenId].toString(), ".png"))
            : "";
    }

    /* INTERNAL FUNCTIONS */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
}
