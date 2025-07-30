// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./tokenV2.sol";

contract NFTMarket {
    // BaseERC721 public nft;
    // BaseERC20 public paymentToken;
    BaseERC721 public immutable nft;
    BaseERC20 public immutable paymentToken;

    struct Listing {
        address seller;
        uint256 price; // 价格（单位是ERC20代币的最小单位）
    }

    // tokenId => Listing
    mapping(uint256 => Listing) public listings;

    event Listed(address indexed seller, uint256 indexed tokenId, uint256 price);
    event Sale(address indexed buyer, uint256 indexed tokenId, uint256 price);
    event Cancelled(address indexed seller, uint256 indexed tokenId);

    constructor(address _nftContract, address _paymentToken) {
        nft = BaseERC721(_nftContract);
        paymentToken = BaseERC20(_paymentToken);
    }

    /**
    @dev NFT持有者上架NFT，指定ERC20代币和价格，NFT转入市场合约托管。
    */
    function list(uint256 tokenId, uint256 price) external {
        require(nft.ownerOf(tokenId) == msg.sender, "Not NFT owner");
        require(price > 0, "Price must be > 0");
       
        // 将NFT转入市场合约托管
        nft.transferFrom(msg.sender, address(this), tokenId);

        listings[tokenId] = Listing(msg.sender, price);

        emit Listed(msg.sender, tokenId, price);
    }

    /**
    @dev 买家购买已上架的NFT，需先approve相应ERC20代币给本合约
    */
    function buyNFT(uint256 tokenId) external {
       //Listing memory item = listings[tokenId];
        Listing storage item = listings[tokenId];
        require(item.price > 0, "NFT not listed");

        uint256 price = item.price;
        address seller = item.seller;

        // 清除上架信息（在转账前清除，避免重入攻击）
        delete listings[tokenId];

        // 买家支付ERC20代币给卖家
        // bool success =paymentToken.transferFrom(msg.sender, item.seller, item.price);
        // require(success, "ERC20 payment failed");

        require(paymentToken.transferFrom(msg.sender, seller, price), "ERC20 payment failed");

        // NFT从市场合约转给买家
        nft.transferFrom(address(this), msg.sender, tokenId);

        emit Sale(msg.sender, tokenId, price);
    }

    /**
    @dev 卖家取消上架，NFT退回卖家
    */
    function cancelListing(uint256 tokenId) external {
       // Listing memory item = listings[tokenId];
        Listing storage item = listings[tokenId];
        require(item.price > 0, "NFT not listed");
        require(item.seller == msg.sender, "Not seller");

        // 清除上架信息
        delete listings[tokenId];

        // NFT退回卖家
        nft.transferFrom(address(this), msg.sender, tokenId);
        
        emit Cancelled(msg.sender, tokenId);
    }

    // 回调
    function tokensReceivedwithId(address from, uint256 amount, uint256 tokenId) external {
        Listing storage item = listings[tokenId];
        require(item.price > 0, "Not listed");
        require(amount >= item.price, "Insufficient amount");

        uint256 price = item.price;
        
        // 清除上架信息
        delete listings[tokenId];

        nft.transferFrom(address(this), from, tokenId);

        emit Sale(from, tokenId, price);
    }

    function getListing(uint256 tokenId) external view returns (address seller, uint256 price) {
        Listing storage listing = listings[tokenId];
        return (listing.seller, listing.price);
    }
}





