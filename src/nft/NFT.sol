// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "../libraries/Constant.sol";
import "../interfaces/IRealNFTForSeperatedCollection.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import {VRFConsumerBaseV2Upgradeable} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Upgradeable.sol";
import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/vrf/interfaces/VRFCoordinatorV2Interface.sol";
import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/shared/interfaces/LinkTokenInterface.sol";

contract NFT is ERC721Upgradeable, Ownable2StepUpgradeable, VRFConsumerBaseV2Upgradeable, ReentrancyGuardUpgradeable {
    using StringsUpgradeable for uint256;

    struct Request {
        uint requestId;
        RequestStatus status;
        uint randomWord;
    }

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

    mapping(uint => Request) public requests; // tokenId to request
    mapping(uint => uint) public requestIdToTokenId;
    bytes32 public keyHash;
    uint16 public requestConfirmation = 3;
    uint32 public callbackGasLimit;

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

    event FundAdded(uint amount);
    event SeperatedCollectionStrategySelected(address realNFT);
    event RevealStarted(RevealStrategy strategy);
    event PriceSet(uint price);
    event VRFConfigSet(bytes32 keyHash, uint16 requestConfirmation, uint32 callbackGasLimit);
    event FeesWithdrawn(uint fee);

    /* MODIFIERS */

    modifier onlySeperatedCollectionStrategy {
        require(realNFTForSeperatedCollection != address(0), "Only SeperatedCollection");
        _;
    }

    modifier onlyNFTOwner(uint _tokenId) {
        require(_ownerOf(_tokenId) == msg.sender, "Only NFT Owner");
        _;
    }

    /* INITIALIZE */
    function initialize() public initializer {
        // init inherited contracts
        __ERC721_init("" , "");
        __Ownable2Step_init();
        __ReentrancyGuard_init();
        __VRFConsumerBaseV2_init(Constant.VRF_COORDINATOR);

        // set variables
        baseURI = Constant.BASE_URI;
        unrevealedURI = Constant.UNREVEALED_URI;
        price = Constant.PRICE;
        COORDINATOR = VRFCoordinatorV2Interface(Constant.VRF_COORDINATOR);
        LINK = LinkTokenInterface(Constant.LINK);
        keyHash = Constant.KEY_HASH;
        requestConfirmation = Constant.REQUEST_CONFIRMATIONS;
        callbackGasLimit = Constant.CALL_BACK_GAS_LIMIT;

        // create subscription to Chainlink VRF2
        subscriptionId = COORDINATOR.createSubscription();
        COORDINATOR.addConsumer(subscriptionId, address(this));
    }

    /* MANAGEMENT FUNCTIONS */
    function addFund(uint _amount) public nonReentrant {
        LINK.transferFrom(msg.sender, address(this), _amount);
        LINK.transferAndCall(address(COORDINATOR), _amount, abi.encode(subscriptionId));
        emit FundAdded(_amount);
    }

    function setRealNFT(address _realNFTForSeperatedCollection) external onlyOwner {
        realNFTForSeperatedCollection = _realNFTForSeperatedCollection;
        emit SeperatedCollectionStrategySelected(_realNFTForSeperatedCollection);
    }

    function startReveal() external onlyOwner {
        require(!hasRevealStarted, "Already reveal started");
        hasRevealStarted = true;

        if (strategy() == RevealStrategy.InCollection) {
            // In Collection case
            require(requests[type(uint).max].status == RequestStatus.NotRequested, "Already requested");
            requests[type(uint).max].status = RequestStatus.Requested;
            _requestRandomWords(type(uint).max);
        } else {
            // Seperated Collection case
            require(realNFTForSeperatedCollection != address(0), "no realNFT address yet");
        }
        emit RevealStarted(strategy());
    }

    function setPrice(uint _price) external onlyOwner {
        price = _price;
        emit PriceSet(_price);
    }

    function setVRFConfig(
        bytes32 _keyHash,
        uint16 _requestConfirmation,
        uint32 _callbackGasLimit
    ) external onlyOwner {
        keyHash = _keyHash;
        requestConfirmation = _requestConfirmation;
        callbackGasLimit = _callbackGasLimit;
        emit VRFConfigSet(_keyHash, _requestConfirmation, _callbackGasLimit);
    }

    function withdrawFee() external onlyOwner {
        uint _fee = address(this).balance;
        payable(owner()).transfer(_fee);
        emit FeesWithdrawn(_fee);
    }

    /* VIEW FUNCTIONS */
    function tokenURI(uint _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "NonexistentId");
        if (strategy() == RevealStrategy.InCollection) {
            if (requests[type(uint).max].status != RequestStatus.FulFilled) {
                return bytes(unrevealedURI).length > 0
                    ? unrevealedURI
                    : "";
            }
        } else {
            if (requests[_tokenId].status != RequestStatus.FulFilled) {
                return bytes(unrevealedURI).length > 0
                ? unrevealedURI
                : "";
            }
        }

        // Only when revealed with InCollection Strategy and tokenOwner's request fulfilled
        return bytes(baseURI).length > 0
            ? string(abi.encodePacked(baseURI, _convert(requests[_tokenId].randomWord).toString(), ".png"))
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

    function linkBalance() public view returns (uint _balance) {
        (_balance,,,) = COORDINATOR.getSubscription(subscriptionId);
    }

    function name() public view override returns (string memory) {
        if (!hasRevealStarted || strategy() == RevealStrategy.SeperatedCollection) {
            return "Unrevealed Rowan's NFT";
        }  else {
            return "Rowan's NFT";
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
    function purchase(uint _mintAmount) public payable nonReentrant  {
        require(!hasRevealStarted, "Already reveal started");
        uint _pay = price * _mintAmount;
        require(msg.value >= _pay, "Not enough");
        require(tokenLength + _mintAmount <= MAX_SUPPLY, "Cannot mint");

        for (uint i; i < _mintAmount; i++) {
            _safeMint(msg.sender, tokenLength);
            tokenLength++;
        }
        if (msg.value > _pay) {
            payable(msg.sender).transfer(msg.value - _pay);
        }
    }

    // Seperated Str
    function reveal(uint _tokenId) external onlyNFTOwner(_tokenId) onlySeperatedCollectionStrategy nonReentrant  {
        require(requests[_tokenId].status == RequestStatus.NotRequested, "Already requested");
        _burn(_tokenId);
        requests[_tokenId].status = RequestStatus.Requested;
        _requestRandomWords(_tokenId);
    }

    /* INTERNAL FUNCTIONS */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function _convert(uint word) internal pure returns (uint) {
        return word % 25;
    }

    // Assumes the subscription is funded sufficiently.
    function _requestRandomWords(uint _tokenId) internal {
        uint32 _numWords = strategy() == RevealStrategy.InCollection ? uint32(MAX_SUPPLY) : 1;
        // Will revert if subscription is not set and funded.
        uint _requestId = COORDINATOR.requestRandomWords(
            Constant.KEY_HASH,
            subscriptionId,
            Constant.REQUEST_CONFIRMATIONS,
            Constant.CALL_BACK_GAS_LIMIT,
            _numWords
        );
        requests[_tokenId].requestId = _requestId;
        requestIdToTokenId[_requestId] = _tokenId;
    }

    function fulfillRandomWords(
        uint256 _requestId, uint256[] memory _randomWords
    ) internal override nonReentrant {
        uint _tokenId = requestIdToTokenId[_requestId];
        require(requests[_tokenId].status == RequestStatus.Requested, "Not requested or already fulfilled");

        if (strategy() == RevealStrategy.InCollection) {
            // In Collection case
            require(_tokenId == type(uint).max, "Only In Collection"); // impossible. double check
            for (uint i; i < _randomWords.length; i++) {
                requests[i].randomWord = requests[i].randomWord;
            }
        } else {
            // Seperated Collection case
            require(_tokenId != type(uint).max, "Only Seperated Collection"); // impossible. double check
            IRealNFTForSeperatedCollection(realNFTForSeperatedCollection).mint(_tokenId, _convert(requests[0].randomWord));
        }

        requests[_tokenId].status = RequestStatus.FulFilled;
    }
}
