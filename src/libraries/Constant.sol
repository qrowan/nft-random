// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

library Constant {
    address public constant LINK = 0x779877A7B0D9E8603169DdbD7836e478b4624789;
    address public constant VRF_COORDINATOR = 0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625;
    bytes32 public constant KEY_HASH = 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c;
    uint public constant PRICE = 0.0001 ether;

    uint32 public constant CALL_BACK_GAS_LIMIT = 1000000;
    uint16 public constant REQUEST_CONFIRMATIONS = 3;

    string public constant BASE_URI = "https://storage.googleapis.com/opensea-prod.appspot.com/puffs/";
    string public constant UNREVEALED_URI = "https://openseacreatures.io/";

    // deployer
    uint64 public constant SUBSCRIPTION_ID = 11629;
    address public constant DEPLOYER = 0xA9f0C55a0d8FC0bcE1027e60b42DcbF5D6D7b56d;
    address public constant PROXY_ADMIN = 0x31d9b6E1A0a76627cFe48A8d03995F621d5fB017;
    address public constant NFT = 0x08AE0f0a7DcA7b4dDa12d682934eFF48F3241F09;
    address public constant REAL_NFT_FOR_SEPERATED_COLLECTION = 0x510A6E848B33E1461A5BA2a10D73fB7b806A398d;
}
