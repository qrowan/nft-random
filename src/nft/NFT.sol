// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "../libraries/Constant.sol";
import "../interfaces/IRealNFTForSeperatedCollection.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";

import {VRFConsumerBaseV2Upgradeable} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Upgradeable.sol";
import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/vrf/interfaces/VRFCoordinatorV2Interface.sol";
import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/shared/interfaces/LinkTokenInterface.sol";

contract NFT is ERC721Upgradeable, Ownable2StepUpgradeable, VRFConsumerBaseV2Upgradeable {
    using StringsUpgradeable for uint256;

    uint public price; // price for 1 NFT
    string public unrevealedURI;
    string public baseURI;
    bool public hasRevealStarted;

    uint public tokenLength;
    uint public constant MAX_SUPPLY = 5;

    VRFCoordinatorV2Interface public COORDINATOR;
    LinkTokenInterface public LINK;
    address public realNFTForSeperatedCollection;

    // VRF V2
    uint64 public subscriptionId;
    mapping(uint => RequestStatus) public requestStatus; // 0: not requested, 1: requested, 2: fulfilled
    mapping(uint => uint) public requestIdToTokenId;
    mapping(uint => uint) public tokenIdToRequestId;
    mapping(uint => uint) public randomWords;

    enum RevealStrategy {
        InCollection,
        SeperatedCollection,
        NotDecidedYet
    }

    enum RequestStatus {
        NotRequested,
        Requested,
        FulFilled
    }

    /* MODIFIERS */
    modifier onlyInCollectionStrategy {
        require(realNFTForSeperatedCollection == address(0), "Only InCollection");
        _;
    }

    modifier onlySeperatedCollectionStrategy {
        require(realNFTForSeperatedCollection != address(0), "Only SeperatedCollection");
        _;
    }

    modifier onlyNFTOwner(uint tokenId) {
        require(_ownerOf(tokenId) == msg.sender, "Only NFT Owner");
        _;
    }

    /* INITIALIZE */
    function initialize() public initializer {
        // init inherited contracts
        __ERC721_init("" , "");
        __Ownable2Step_init();
        __VRFConsumerBaseV2_init(Constant.VRF_COORDINATOR);

        // set variables
        baseURI = Constant.BASE_URI;
        unrevealedURI = Constant.UNREVEALED_URI;
        price = 0.00001 ether;
        COORDINATOR = VRFCoordinatorV2Interface(Constant.VRF_COORDINATOR);
        LINK = LinkTokenInterface(Constant.LINK);

        // create subscription to Chainlink VRF2
        subscriptionId = COORDINATOR.createSubscription();
        COORDINATOR.addConsumer(subscriptionId, address(this));
    }

    /* MANAGEMENT FUNCTIONS */
    function addFund(uint amount) public {
        LINK.transferFrom(msg.sender, address(this), amount);
        LINK.transferAndCall(address(COORDINATOR), amount, abi.encode(subscriptionId));
    }

    function setRealNFT(address _realNFTForSeperatedCollection) external onlyOwner {
        realNFTForSeperatedCollection = _realNFTForSeperatedCollection;
    }

    function startReveal() external onlyOwner {
        require(!hasRevealStarted, "Already reveal started");
        hasRevealStarted = true;

        if (strategy() == RevealStrategy.InCollection) {
            require(requestStatus[type(uint).max] == RequestStatus.NotRequested, "Already requested");
            // In Collection case
            _requestRandomWords(type(uint).max);
            requestStatus[type(uint).max] = RequestStatus.Requested;
        } else {
            // Seperated Collection case
            require(realNFTForSeperatedCollection != address(0), "no realNFT address yet");
        }
    }

    function withdrawFee() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    /* VIEW FUNCTIONS */
    function tokenURI(uint tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "NonexistentId");
        if (requestStatus[tokenId] != RequestStatus.FulFilled) {
            return bytes(unrevealedURI).length > 0
            ? unrevealedURI
            : "";
        }

        // Only when revealed with InCollection Strategy and tokenOwner's request fulfilled
        return bytes(baseURI).length > 0
            ? string(abi.encodePacked(baseURI, _convert(tokenId).toString(), ".png"))
            : "";
    }

    function strategy() public view returns (RevealStrategy) {
        if (!hasRevealStarted) {
            return RevealStrategy.NotDecidedYet;
        } else {
            if (realNFTForSeperatedCollection == address(0)) {
                return RevealStrategy.InCollection;
            } else {
                return RevealStrategy.SeperatedCollection;
            }
        }
    }

    function linkBalance() public view returns (uint balance) {
        (balance,,,) = COORDINATOR.getSubscription(subscriptionId);
    }

    function name() public view override returns (string memory) {
        if (!hasRevealStarted || strategy() == RevealStrategy.SeperatedCollection) {
            return "Unrevealed Rowan' NFT";
        }  else {
            return "Rowan' NFT";
        }
    }

    function symbol() public view override returns (string memory) {
        if (!hasRevealStarted || strategy() == RevealStrategy.SeperatedCollection) {
            return "uROWAN";
        }  else {
            return "ROWAN";
        }
    }

    /* MUTATIVE FUNCTIONS */
    function purchase(uint _mintAmount) public payable {
        require(!hasRevealStarted, "Already reveal started");
        uint pay = price * _mintAmount;
        require(msg.value >= pay, "Not enough");
        require(tokenLength + _mintAmount <= MAX_SUPPLY, "Cannot mint");

        for (uint i; i < _mintAmount; i++) {
            _safeMint(msg.sender, tokenLength);
            tokenLength++;
        }
        if (msg.value > pay) {
            payable(msg.sender).transfer(msg.value - pay);
        }
    }

    // Seperated Str
    function reveal(uint tokenId) external onlyNFTOwner(tokenId) onlySeperatedCollectionStrategy {
        require(requestStatus[tokenId] == RequestStatus.NotRequested, "Already requested");
        _burn(tokenId);
        requestStatus[tokenId] = RequestStatus.Requested;
        _requestRandomWords(tokenId);
    }

    /* INTERNAL FUNCTIONS */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function _convert(uint tokenId) internal view returns (uint) {
        if (!hasRevealStarted) return 0;
        require(strategy() == RevealStrategy.InCollection, "Only InCollection");
        return randomWords[tokenId] % 25;
    }

    // Assumes the subscription is funded sufficiently.
    function _requestRandomWords(uint tokenId) internal {
        uint32 numWords = strategy() == RevealStrategy.InCollection ? uint32(MAX_SUPPLY) : 1;
        // Will revert if subscription is not set and funded.
        uint _requestId = COORDINATOR.requestRandomWords(
            Constant.KEY_HASH,
            subscriptionId,
            Constant.REQUEST_CONFIRMATIONS,
            Constant.CALL_BACK_GAS_LIMIT,
            numWords
        );
        tokenIdToRequestId[tokenId] = _requestId;
        requestIdToTokenId[_requestId] = tokenId;
    }

    function fulfillRandomWords(
        uint256 _requestId, uint256[] memory _randomWords
    ) internal override {
        uint tokenId = requestIdToTokenId[_requestId];
        require(requestStatus[tokenId] == RequestStatus.Requested, "Not requested or already fulfilled");

        if (strategy() == RevealStrategy.InCollection) {
            // In Collection case
            require(tokenId == type(uint).max, "Only In Collection"); // impossible. double check
            for (uint i; i < _randomWords.length; i++) {
                randomWords[i] = _randomWords[i];
            }
        } else {
            // Seperated Collection case
            require(tokenId != type(uint).max, "Only Seperated Collection"); // impossible. double check
            IRealNFTForSeperatedCollection(realNFTForSeperatedCollection).mint(tokenId, randomWords[tokenId]);
        }

        requestStatus[tokenId] = RequestStatus.FulFilled;
    }
}
