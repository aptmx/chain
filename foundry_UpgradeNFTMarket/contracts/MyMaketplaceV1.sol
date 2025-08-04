// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import "./MyERC721Upgradeable.sol";
import "./MyERC20Upgradeable.sol";

contract MyMaketplaceV1 is Initializable, OwnableUpgradeable, UUPSUpgradeable {

    MyERC721Upgradeable public nftContract;
    MyERC20Upgradeable public tokenContract;
    
    // 上架信息结构
    struct Listing {
        address seller;
        uint256 price;
        bool isActive;
    }
    
    // tokenId => 上架信息
    mapping(uint256 => Listing) public listings;
    
    // 事件
    event NFTListed(uint256 indexed tokenId, address indexed seller, uint256 price);
    event NFTSold(uint256 indexed tokenId, address indexed seller, address indexed buyer, uint256 price);
    event ListingCancelled(uint256 indexed tokenId, address indexed seller);
    
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }
    
    function initialize(address _nftContract, address _tokenContract) public initializer {
        __Ownable_init(msg.sender);
        nftContract = MyERC721Upgradeable(_nftContract);
        tokenContract = MyERC20Upgradeable(_tokenContract);
    }
    
   
    function list(uint256 tokenId, uint256 price) external {
        require(price > 0, "Price must be greater than 0");
        require(nftContract.ownerOf(tokenId) == msg.sender, "Not the owner of this NFT");
        require(nftContract.isApprovedForAll(msg.sender, address(this)) || 
                nftContract.getApproved(tokenId) == address(this), "NFT not approved for marketplace");
        
        listings[tokenId] = Listing({
            seller: msg.sender,
            price: price,
            isActive: true
        });
        
        emit NFTListed(tokenId, msg.sender, price);
    }
    
  
    function buyNFT(uint256 tokenId) external {
        Listing storage listing = listings[tokenId];
        require(listing.isActive, "NFT not listed for sale");
        require(msg.sender != listing.seller, "Cannot buy your own NFT");
        
        // 转移ERC20代币
        require(tokenContract.transferFrom(msg.sender, listing.seller, listing.price), "Token transfer failed");
        
        // 转移NFT
        nftContract.safeTransferFrom(listing.seller, msg.sender, tokenId);
        
        // 更新上架状态
        listing.isActive = false;
        
        emit NFTSold(tokenId, listing.seller, msg.sender, listing.price);
    }
    

    
    /**
     * @dev 取消上架
     * @param tokenId NFT的ID
     */
    function cancelListing(uint256 tokenId) external {
        Listing storage listing = listings[tokenId];
        require(listing.seller == msg.sender, "Not the seller");
        require(listing.isActive, "Listing not active");
        
        listing.isActive = false;
        
        emit ListingCancelled(tokenId, msg.sender);
    }
    
    /**
     * @dev 获取上架信息
     * @param tokenId NFT的ID
     */
    function getListing(uint256 tokenId) external view returns (address seller, uint256 price, bool isActive) {
        Listing storage listing = listings[tokenId];
        return (listing.seller, listing.price, listing.isActive);
    }
    
    function _authorizeUpgrade(address) internal override {    
    }
}
