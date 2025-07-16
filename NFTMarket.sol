// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "./ERC721.sol";
import "./tokenV2.sol";


contract NFTMarket {
    BaseERC721 public nft;
    BaseERC20 public paymentToken;
    

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

        listings[tokenId] = Listing({
        seller: msg.sender,
        price: price
    });

    emit Listed(msg.sender, tokenId, price);
    }

    /**
    @dev 买家购买已上架的NFT，需先approve相应ERC20代币给本合约
    */
    function buyNFT(uint256 tokenId) external {
        Listing memory item = listings[tokenId];
        require(item.price > 0, "NFT not listed");

        // 买家支付ERC20代币给卖家
        bool success =paymentToken.transferFrom(msg.sender, item.seller, item.price);
        require(success, "ERC20 payment failed");

        // NFT从市场合约转给买家
        nft.transferFrom(address(this), msg.sender, tokenId);

        // 清除上架信息
        delete listings[tokenId];

        emit Sale(msg.sender, tokenId, item.price);
    }

    /**
    @dev 卖家取消上架，NFT退回卖家
    */
    function cancelListing(uint256 tokenId) external {
        Listing memory item = listings[tokenId];
        require(item.price > 0, "NFT not listed");
        require(item.seller == msg.sender, "Not seller");

        // NFT退回卖家
        nft.transferFrom(address(this), msg.sender, tokenId);
        delete listings[tokenId];
        emit Cancelled(msg.sender, tokenId);
    }

    // 回调
    function tokensReceived(address from, uint256 amount, uint256 tokenId) external {
        Listing memory item = listings[tokenId];
        require(item.price > 0, "Not listed");
        require(amount >= item.price, "Insufficient amount");

        nft.transferFrom(address(this), from, tokenId);
        delete listings[tokenId];

        emit Sale(from, tokenId, amount);
    }
}





