// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

library Constant {
    address public constant LINK = 0x779877A7B0D9E8603169DdbD7836e478b4624789;
    address public constant VRF_COORDINATOR = 0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625;
    bytes32 public constant KEY_HASH = 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c;
    uint public constant PRICE = 0.0001 ether;

    uint32 public constant CALL_BACK_GAS_LIMIT = 10000;
    uint16 public constant REQUEST_CONFIRMATIONS = 3;

    string public constant BASE_URI = "https://storage.googleapis.com/opensea-prod.appspot.com/puffs/";
    string public constant UNREVEALED_URI = "https://openseacreatures.io/";

    // sample
    address public constant VRF_V2_CONSUMER = 0x51602415DD645d9e48FCBD21a00094453d4118f4; // sample
    uint64 public constant SUBSCRIPTION_ID = 11604; // sample
}
