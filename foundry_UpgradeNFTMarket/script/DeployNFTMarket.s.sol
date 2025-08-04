// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {MyERC20Upgradeable} from "../contracts/MyERC20Upgradeable.sol";
import {MyERC721Upgradeable} from "../contracts/MyERC721Upgradeable.sol";
import {MyERC721V2} from "../contracts/MyERC721V2.sol";
import {MyMaketplaceV1} from "../contracts/MyMaketPlaceV1.sol";
import {MyMarketPalceV2} from "../contracts/MyMarketPalceV2.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract DeployNFTMarketScript is Script {
    // 实现合约
    MyERC20Upgradeable public tokenImplementation;
    MyERC721Upgradeable public nftImplementation;
    MyERC721V2 public nftV2Implementation;
    MyMaketplaceV1 public marketplaceImplementation;
    MyMarketPalceV2 public marketplaceV2Implementation;
    
    // 代理合约
    TransparentUpgradeableProxy public tokenProxy;
    TransparentUpgradeableProxy public nftProxy;
    TransparentUpgradeableProxy public marketplaceProxy;
    
    // ProxyAdmin
    ProxyAdmin public proxyAdmin;
    
    // 代理合约接口
    MyERC20Upgradeable public token;
    MyERC721Upgradeable public nft;
    MyERC721V2 public nftV2;
    MyMaketplaceV1 public marketplace;
    MyMarketPalceV2 public marketplaceV2;

    function setUp() public {}

    function run() public {
        address deployer = msg.sender;
        console.log("Deployer address:", deployer);
        
        vm.startBroadcast();

        // 1. 部署 ProxyAdmin
        console.log("Deploying ProxyAdmin...");
        proxyAdmin = new ProxyAdmin(deployer);
        console.log("ProxyAdmin deployed at:", address(proxyAdmin));

        // 2. 部署 V1 实现合约
        console.log("Deploying V1 implementation contracts...");
        tokenImplementation = new MyERC20Upgradeable();
        nftImplementation = new MyERC721Upgradeable();
        marketplaceImplementation = new MyMaketplaceV1();
        
        console.log("Token V1 implementation deployed at:", address(tokenImplementation));
        console.log("NFT V1 implementation deployed at:", address(nftImplementation));
        console.log("Marketplace V1 implementation deployed at:", address(marketplaceImplementation));

        // 3. 部署 V2 实现合约
        console.log("Deploying V2 implementation contracts...");
        nftV2Implementation = new MyERC721V2();
        marketplaceV2Implementation = new MyMarketPalceV2();
        
        console.log("NFT V2 implementation deployed at:", address(nftV2Implementation));
        console.log("Marketplace V2 implementation deployed at:", address(marketplaceV2Implementation));

        // 4. 部署代理合约
        console.log("Deploying proxy contracts...");
        
        // 部署 ERC20 代币代理
        bytes memory tokenInitData = abi.encodeWithSelector(
            MyERC20Upgradeable.initialize.selector,
            "LittleStar",      // name
            "LSR",             // symbol
            1000000 * 10**18   // initial supply (1 million tokens)
        );
        tokenProxy = new TransparentUpgradeableProxy(
            address(tokenImplementation),
            address(proxyAdmin),
            tokenInitData
        );
        token = MyERC20Upgradeable(address(tokenProxy));
        
        // 部署 ERC721 NFT 代理
        bytes memory nftInitData = abi.encodeWithSelector(
            MyERC721Upgradeable.initialize.selector,
            "Dragon",          // name
            "DRG"              // symbol
        );
        nftProxy = new TransparentUpgradeableProxy(
            address(nftImplementation),
            address(proxyAdmin),
            nftInitData
        );
        nft = MyERC721Upgradeable(address(nftProxy));
        
        // 部署市场代理
        bytes memory marketplaceInitData = abi.encodeWithSelector(
            MyMaketplaceV1.initialize.selector,
            address(nft),      // NFT合约地址
            address(token)     // 代币合约地址
        );
        marketplaceProxy = new TransparentUpgradeableProxy(
            address(marketplaceImplementation),
            address(proxyAdmin),
            marketplaceInitData
        );
        marketplace = MyMaketplaceV1(address(marketplaceProxy));

        console.log("Token proxy deployed at:", address(token));
        console.log("NFT proxy deployed at:", address(nft));
        console.log("Marketplace proxy deployed at:", address(marketplace));

        // 5. 验证部署
        console.log("Verifying deployment...");
        console.log("Token name:", token.name());
        console.log("Token symbol:", token.symbol());
        console.log("Token total supply:", token.totalSupply() / 10**18, "tokens");
        console.log("Token deployer balance:", token.balanceOf(deployer) / 10**18, "tokens");
        
        console.log("NFT name:", nft.name());
        console.log("NFT symbol:", nft.symbol());
        
        console.log("Marketplace NFT contract:", address(marketplace.nftContract()));
        console.log("Marketplace token contract:", address(marketplace.tokenContract()));

        vm.stopBroadcast();
        
        // 6. 输出部署摘要
        console.log("\n=== DEPLOYMENT SUMMARY ===");
        console.log("ProxyAdmin:", address(proxyAdmin));
        console.log("");
        console.log("V1 Implementation Contracts:");
        console.log("- Token V1:", address(tokenImplementation));
        console.log("- NFT V1:", address(nftImplementation));
        console.log("- Marketplace V1:", address(marketplaceImplementation));
        console.log("");
        console.log("V2 Implementation Contracts:");
        console.log("- NFT V2:", address(nftV2Implementation));
        console.log("- Marketplace V2:", address(marketplaceV2Implementation));
        console.log("");
        console.log("Proxy Contracts:");
        console.log("- Token Proxy:", address(token));
        console.log("- NFT Proxy:", address(nft));
        console.log("- Marketplace Proxy:", address(marketplace));
        console.log("");
        console.log("Deployer:", deployer);
        console.log("Deployer token balance:", token.balanceOf(deployer) / 10**18, "LSR");
        console.log("========================\n");
        
        // 7. 输出升级命令示例
        console.log("=== UPGRADE COMMANDS ===");
        console.log("To upgrade NFT to V2:");
        console.log("cast send");
        console.log("ProxyAdmin:", address(proxyAdmin));
        console.log("NFT Proxy:", address(nftProxy));
        console.log("NFT V2 Implementation:", address(nftV2Implementation));
        console.log("");
        console.log("To upgrade Marketplace to V2:");
        console.log("cast send");
        console.log("ProxyAdmin:", address(proxyAdmin));
        console.log("Marketplace Proxy:", address(marketplaceProxy));
        console.log("Marketplace V2 Implementation:", address(marketplaceV2Implementation));
        console.log("=======================\n");
    }
} 