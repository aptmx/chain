// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "./MyERC721Upgradeable.sol";
import "./MyERC20Upgradeable.sol";

contract MyMarketPalceV2 is Initializable, OwnableUpgradeable, EIP712 {
    
    using ECDSA for bytes32;
    
    // NFT合约地址
    MyERC721Upgradeable public nftContract;
    // ERC20代币合约地址
    MyERC20Upgradeable public tokenContract;
    
    // 上架信息结构
    struct Listing {
        address seller;
        uint256 price;
        bool isActive;
    }
    
    // tokenId => 上架信息
    mapping(uint256 => Listing) public listings;
    
    // 已使用的签名nonce，防止重放攻击
    mapping(bytes32 => bool) public usedSignatures;
    
    // 签名域名和版本
    string private constant SIGNING_DOMAIN = "NFTMarketplaceV2";
    string private constant SIGNATURE_VERSION = "1";
    
    // 签名结构
    struct ListingSignature {
        uint256 tokenId;
        uint256 price;
        uint256 nonce;
        uint256 deadline;
    }
    
    // 事件
    event NFTListed(uint256 indexed tokenId, address indexed seller, uint256 price);
    event NFTSold(uint256 indexed tokenId, address indexed seller, address indexed buyer, uint256 price);
    event ListingCancelled(uint256 indexed tokenId, address indexed seller);
    event SignatureUsed(bytes32 indexed signatureHash, address indexed signer);
    
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() EIP712(SIGNING_DOMAIN, SIGNATURE_VERSION) {
        _disableInitializers();
    }
    
    function initialize(address _nftContract, address _tokenContract) public initializer {
        __Ownable_init(msg.sender);
        nftContract = MyERC721Upgradeable(_nftContract);
        tokenContract = MyERC20Upgradeable(_tokenContract);
    }
    
    //兼容V1
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
    
  
    function listWithSignature(
        uint256 tokenId,
        uint256 price,
        uint256 nonce,
        uint256 deadline,
        bytes calldata signature
    ) external {
        require(price > 0, "Price must be greater than 0");
        require(deadline >= block.timestamp, "Signature expired");
        
        // 构建签名数据
        ListingSignature memory listingData = ListingSignature({
            tokenId: tokenId,
            price: price,
            nonce: nonce,
            deadline: deadline
        });
        
        // 计算签名哈希
        bytes32 structHash = _hashListingSignature(listingData);
        bytes32 signatureHash = _hashTypedDataV4(structHash);
        
        // 检查签名是否已使用
        require(!usedSignatures[signatureHash], "Signature already used");
        
        // 验证签名
        address signer = signatureHash.recover(signature);
        require(signer == nftContract.ownerOf(tokenId), "Invalid signature or not NFT owner");
        
        // 检查NFT是否已授权给市场合约
        require(nftContract.isApprovedForAll(signer, address(this)), "NFT not approved for marketplace");
        
        // 标记签名已使用
        usedSignatures[signatureHash] = true;
        
        // 创建上架信息
        listings[tokenId] = Listing({
            seller: signer,
            price: price,
            isActive: true
        });
        
        emit NFTListed(tokenId, signer, price);
        emit SignatureUsed(signatureHash, signer);
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

    function cancelListing(uint256 tokenId) external {
        Listing storage listing = listings[tokenId];
        require(listing.seller == msg.sender, "Not the seller");
        require(listing.isActive, "Listing not active");
        
        listing.isActive = false;
        
        emit ListingCancelled(tokenId, msg.sender);
    }
    
   
    function getListing(uint256 tokenId) external view returns (address seller, uint256 price, bool isActive) {
        Listing storage listing = listings[tokenId];
        return (listing.seller, listing.price, listing.isActive);
    }
    
 
    function isSignatureUsed(bytes32 signatureHash) external view returns (bool) {
        return usedSignatures[signatureHash];
    }
    
   
    function _hashListingSignature(ListingSignature memory listingData) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            keccak256("ListingSignature(uint256 tokenId,uint256 price,uint256 nonce,uint256 deadline)"),
            listingData.tokenId,
            listingData.price,
            listingData.nonce,
            listingData.deadline
        ));
    }
    
    /**
     * @dev 获取签名域名分隔符（用于前端签名）
     */
    function getDomainSeparator() external view returns (bytes32) {
        return _domainSeparatorV4();
    }
    
    /**
     * @dev 获取签名类型哈希（用于前端签名）
     */
    function getListingSignatureTypeHash() external pure returns (bytes32) {
        return keccak256("ListingSignature(uint256 tokenId,uint256 price,uint256 nonce,uint256 deadline)");
    }
    
    function proxiableUUID() external view virtual returns (bytes32) {
        return 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
    }
}
