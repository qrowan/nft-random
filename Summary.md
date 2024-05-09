# Summary
This project is for a service that mints NFT with image URI. Users can purchase NFT by paying ETH, but it contains a default URI for all tokenID. Owner can choose a strategy in belows :
1. In-Collection
   * All URI are revealed at once by owner.
2. Seperated-Collection
   * Users reveal their own NFT by themselves.

With In-Collection strategy, users NFT address will be lasted and URI would be changed to revealed one. Otherwise, with Seperated-Collection strategy, users will get newly minted NFT with revealed URI.

## NFT.sol
The Initial NFT contract for all strategy. tokenURI will have changed after revealing if in In-Collection strategy.
```solidity
// purchase NFT
function purchase(uint _mintAmount) external;
// URI for tokenId
function tokenURI(uint _tokenId) public view virtual override returns (string memory)
```

## RealNFTForSeperatedCollection.sol
The NFT contract only used in Seperated-Collection strategy that contains real URI
```solidity
// URI for tokenId
function tokenURI(uint _tokenId) public view virtual override returns (string memory)
```