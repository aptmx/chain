// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {MyERC20Upgradeable} from "../contracts/MyERC20Upgradeable.sol";
import {MyERC721Upgradeable} from "../contracts/MyERC721Upgradeable.sol";
import {MyERC721V2} from "../contracts/MyERC721V2.sol";
import {MyMaketplaceV1} from "../contracts/MyMaketPlaceV1.sol";
import {MyMarketPalceV2} from "../contracts/MyMarketPalceV2.sol";

import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {TransparentUpgradeableProxy, ITransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract NFTMarketplaceTest is Test {
    // 实现合约
    MyERC20Upgradeable public tokenImplementation;
    MyERC721Upgradeable public nftImplementation;
    MyERC721V2 public nftV2Implementation;
    MyMaketplaceV1 public marketplaceImplementation;
    MyMarketPalceV2 public marketplaceV2Implementation;

    // 代理合约
    ITransparentUpgradeableProxy public tokenProxy;
    ITransparentUpgradeableProxy public nftProxy;
    ITransparentUpgradeableProxy public marketplaceProxy;

    // ProxyAdmin 合约
    ProxyAdmin public proxyAdmin;

    // 代理合约对应接口
    MyERC20Upgradeable public token;
    MyERC721Upgradeable public nft;
    MyERC721V2 public nftV2;
    MyMaketplaceV1 public marketplace;
    MyMarketPalceV2 public marketplaceV2;

    // 测试账户
    address public owner;
    address public user1;
    address public user2;

    function setUp() public {
        owner = makeAddr("owner");
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");

        vm.startPrank(owner);

        // 1. 部署实现合约
        tokenImplementation = new MyERC20Upgradeable();
        nftImplementation = new MyERC721Upgradeable();
        nftV2Implementation = new MyERC721V2();
        marketplaceImplementation = new MyMaketplaceV1();
        marketplaceV2Implementation = new MyMarketPalceV2();

        // 2. 部署 ProxyAdmin
        proxyAdmin = new ProxyAdmin(owner);

        // 3. 编码初始化数据
        bytes memory tokenInitData = abi.encodeWithSelector(
            MyERC20Upgradeable.initialize.selector,
            "LittleStar",
            "LSR",
            1000000 * 10**18
        );
        bytes memory nftInitData = abi.encodeWithSelector(
            MyERC721Upgradeable.initialize.selector,
            "Dragon",
            "DRG"
        );


        // 4. 部署 token 和 nft 代理合约
        tokenProxy = ITransparentUpgradeableProxy(address(new TransparentUpgradeableProxy(
            address(tokenImplementation),
            address(proxyAdmin),
            tokenInitData
        )));
        token = MyERC20Upgradeable(address(tokenProxy));

        nftProxy = ITransparentUpgradeableProxy(address(new TransparentUpgradeableProxy(
            address(nftImplementation),
            address(proxyAdmin),
            nftInitData
        )));
        nft = MyERC721Upgradeable(address(nftProxy));

        // 5. 部署 marketplace 代理合约，使用正确的地址
        bytes memory marketplaceInitData = abi.encodeWithSelector(
            MyMaketplaceV1.initialize.selector,
            address(nft),
            address(token)
        );
        
       marketplaceProxy = ITransparentUpgradeableProxy(address(new TransparentUpgradeableProxy(
            address(marketplaceImplementation),
            address(proxyAdmin),
            marketplaceInitData
        )));
        marketplace = MyMaketplaceV1(address(marketplaceProxy));

        vm.stopPrank();
    }

    // 简单检查初始化数据
    function test_InitialDeployment() public view {
        assertEq(token.name(), "LittleStar");
        assertEq(token.symbol(), "LSR");
        assertEq(token.totalSupply(), 1000000 * 10**18);
        assertEq(token.balanceOf(owner), 1000000 * 10**18);

        assertEq(nft.name(), "Dragon");
        assertEq(nft.symbol(), "DRG");

        assertEq(address(marketplace.nftContract()), address(nft));
        assertEq(address(marketplace.tokenContract()), address(token));
    }

    // NFT 铸造、上架测试
    function test_MintAndListNFT() public {
        vm.startPrank(owner);

        nft.mint(owner, 1, "ipfs://QmTest1");
        assertEq(nft.ownerOf(1), owner);

        nft.setApprovalForAll(address(marketplace), true);
        marketplace.list(1, 100 * 10**18);

        (address seller, uint256 price, bool isActive) = marketplace.getListing(1);
        assertEq(seller, owner);
        assertEq(price, 100 * 10**18);
        assertTrue(isActive);

        vm.stopPrank();
    }

    // 购买测试
    function test_BuyNFT() public {
        vm.startPrank(owner);

        nft.mint(owner, 1, "ipfs://QmTest1");
        nft.setApprovalForAll(address(marketplace), true);
        marketplace.list(1, 100 * 10**18);

        token.transfer(user1, 200 * 10**18);

        vm.stopPrank();

        vm.startPrank(user1);

        token.approve(address(marketplace), 100 * 10**18);
        marketplace.buyNFT(1);

        assertEq(nft.ownerOf(1), user1);
        assertEq(token.balanceOf(user1), 100 * 10**18); // 200 - 100
        assertEq(token.balanceOf(owner), 1000000 * 10**18 - 200 * 10**18 + 100 * 10**18);

        vm.stopPrank();
    }

    // 升级NFT合约测试
    function test_UpgradeNFTToV2() public {
        vm.startPrank(owner);

        proxyAdmin.upgradeAndCall(nftProxy, address(nftV2Implementation), "");
        nftV2 = MyERC721V2(address(nftProxy));

        // 升级后设置角色
        nftV2.setupRolesAfterUpgrade(owner);

        nftV2.mint(owner, 100);
        assertEq(nftV2.ownerOf(100), owner);

        vm.stopPrank();
    }

    // 升级市场合约测试
    function test_UpgradeMarketplaceToV2() public {
        vm.startPrank(owner);

        proxyAdmin.upgradeAndCall(marketplaceProxy, address(marketplaceV2Implementation), "");
        marketplaceV2 = MyMarketPalceV2(address(marketplaceProxy));

        nft.mint(owner, 1, "ipfs://QmTest1");
        nft.setApprovalForAll(address(marketplaceV2), true);

        // 这里你可以继续调用 marketplaceV2 的新方法测试...

        vm.stopPrank();
    }

    // 失败场景举例
    function test_RevertCases() public {
        vm.startPrank(owner);
        vm.stopPrank();

        vm.startPrank(user1);
        vm.expectRevert();
        nft.mint(user1, 1, "ipfs://QmTest1");
        vm.stopPrank();
    }
    
    // 测试非 owner 无法升级合约
    function test_NonOwnerCannotUpgrade() public {
        vm.startPrank(user1);
        
        // user1 尝试升级 NFT 合约，应该失败
        vm.expectRevert();
        proxyAdmin.upgradeAndCall(nftProxy, address(nftV2Implementation), "");
        
        vm.stopPrank();
    }
    
    // 测试只有 owner 才能升级合约
    function test_OnlyOwnerCanUpgrade() public {
        vm.startPrank(owner);
        
        // owner 应该能够成功升级
        proxyAdmin.upgradeAndCall(nftProxy, address(nftV2Implementation), "");
        nftV2 = MyERC721V2(address(nftProxy));
        
        // 验证升级成功
        nftV2.setupRolesAfterUpgrade(owner);
        nftV2.mint(owner, 999);
        assertEq(nftV2.ownerOf(999), owner);
        
        vm.stopPrank();
    }

    // 辅助
    function ownerPrivateKey() internal pure returns (uint256) {
        return 0xA11CE;
    }
}
