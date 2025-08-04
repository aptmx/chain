// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";


contract MyERC721Upgradeable is Initializable, ERC721URIStorageUpgradeable, OwnableUpgradeable, UUPSUpgradeable {
    
    
    /// @custom:oz-upgrades-unsafe-allow constructor

    constructor() {
        _disableInitializers();
    }
    
    function initialize(string memory name, string memory symbol) public initializer {
        __ERC721_init(name, symbol);
        __ERC721URIStorage_init();
        __Ownable_init(msg.sender);
    }
    
    function mint(address to, uint256 tokenId, string memory uri) public onlyOwner {
        _mint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }
    
    function burn(uint256 tokenId) public {
        require(ownerOf(tokenId) == msg.sender || getApproved(tokenId) == msg.sender || isApprovedForAll(ownerOf(tokenId), msg.sender), "ERC721: caller is not token owner or approved");
        _burn(tokenId);
    }
    
    function _authorizeUpgrade(address) internal override {
     
    }
    

}