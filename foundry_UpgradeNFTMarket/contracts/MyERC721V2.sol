// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";

contract MyERC721V2 is Initializable, ERC721Upgradeable, OwnableUpgradeable, AccessControlUpgradeable, EIP712 {
    
    using ECDSA for bytes32;
    
    // 签名域名和版本
    string private constant SIGNING_DOMAIN = "ERC721V2";
    string private constant SIGNATURE_VERSION = "1";
    
    // 每个地址的nonce，防止重放攻击
    mapping(address => uint256) public nonces;
    
    // 事件
    event PermitUsed(address indexed owner, address indexed spender, uint256 nonce);
    
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() EIP712(SIGNING_DOMAIN, SIGNATURE_VERSION) {
        _disableInitializers();
    }
    
    function initialize(string memory name, string memory symbol) public initializer {
        __ERC721_init(name, symbol);
        __Ownable_init(msg.sender);
        __AccessControl_init();
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(keccak256("MINTER_ROLE"), msg.sender);
    }
    
  
    function mint(address to, uint256 tokenId) public {
        require(hasRole(keccak256("MINTER_ROLE"), msg.sender), "Must have minter role");
        _mint(to, tokenId);
    }
    

    function permit(
        address owner,
        address spender,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(deadline >= block.timestamp, "Permit expired");
        require(owner == this.owner(), "Invalid owner");
        
        uint256 nonce = nonces[owner]++;
        
        // 计算签名哈希
        bytes32 structHash = keccak256(abi.encode(
            keccak256("Permit(address owner,address spender,uint256 nonce,uint256 deadline)"),
            owner,
            spender,
            nonce,
            deadline
        ));
        bytes32 hash = _hashTypedDataV4(structHash);
        
        // 验证签名
        address signer = ecrecover(hash, v, r, s);
        require(signer == owner, "Invalid signature");
        
        // 授权铸造权限
        _grantRole(keccak256("MINTER_ROLE"), spender);
        
        emit PermitUsed(owner, spender, nonce);
    }
    

    function burn(uint256 tokenId) public {
        require(ownerOf(tokenId) == msg.sender || getApproved(tokenId) == msg.sender || isApprovedForAll(ownerOf(tokenId), msg.sender), "ERC721: caller is not token owner or approved");
        _burn(tokenId);
    }
    
    
    function getNonce(address owner) external view returns (uint256) {
        return nonces[owner];
    }
    
    /**
     * @dev 获取签名域名分隔符（用于前端签名）
     */
    function getDomainSeparator() external view returns (bytes32) {
        return _domainSeparatorV4();
    }
    
    /**
     * @dev 获取permit类型哈希（用于前端签名）
     */
    function getPermitTypeHash() external pure returns (bytes32) {
        return keccak256("Permit(address owner,address spender,uint256 nonce,uint256 deadline)");
    }
    
    function supportsInterface(bytes4 interfaceId) public view override(ERC721Upgradeable, AccessControlUpgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
    
    // 升级后设置角色的函数，只有 owner 可以调用
    function setupRolesAfterUpgrade(address _owner) external onlyOwner {
        _grantRole(DEFAULT_ADMIN_ROLE, _owner);
        _grantRole(keccak256("MINTER_ROLE"), _owner);
    }
    
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     */
    function proxiableUUID() external view virtual returns (bytes32) {
        return 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
    }
    

    

} 