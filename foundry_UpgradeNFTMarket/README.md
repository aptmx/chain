# 升级 NFT 市场合约

这是一个基于 Foundry 的升级 NFT 市场合约项目，使用透明代理模式实现合约升级功能。

## 项目概述

本项目包含以下核心合约：
  
  V1 Implementation Contracts:
  - Token V1: 0x8C777593A48E696e0d6582a49c03CA55f9a7282B
  - NFT V1: 0x547EFC6982c0de1CdBF20157e7E2FEc97AE509B6
  - Marketplace V1: 0x241d40A11BD7BBaA6CaB4b54c5A74556367F6288
  
  V2 Implementation Contracts:
  - NFT V2: 0xC5088c92cCa89c68390F4A9774A3D9BE8f6c66Dd
  - Marketplace V2: 0x094F67022156a3F95800aE78184da36B210b74b3
  
  Proxy Contracts:
  - ProxyAdmin: 0x0029dE0a5722b13eA506cB114FbDD0Ee4bB458f5
  - Token Proxy: 0xCF8b0EDd758Aa5502E0078393BB455B859D73126
  - NFT Proxy: 0x86f1d9AE33546BfB08437e63618057d90761d76B
  - Marketplace Proxy: 0xF259D06427E861f0BA336fF8c7Ca5ABefdc279ba
  
  =======================

## 功能特性

### V1 功能
- ERC20 代币铸造和转账
- ERC721 NFT 铸造和交易
- NFT 上架和购买功能
- 基本的市场交易

### V2 升级功能
- **离线签名上架**: 使用 EIP712 签名实现无需 gas 的 NFT 上架
- **ERC721 Permit**: 类似 EIP-2612 的 permit 功能，支持签名授权铸造权限
- **角色管理**: 基于 AccessControl 的角色权限系统

## 安全特性

- **透明代理**: 使用 OpenZeppelin 的 TransparentUpgradeableProxy
- **权限控制**: 只有 ProxyAdmin 的 owner 才能升级合约
- **签名验证**: 使用 ECDSA 和 EIP712 进行安全的离线签名验证
- **重放保护**: 使用 nonce 机制防止签名重放攻击

## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

-   **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
-   **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
-   **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
-   **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

#### 运行所有测试
```shell
$ forge test
```

#### 运行特定测试
```shell
# 运行升级测试
$ forge test --match-test test_UpgradeNFTToV2
$ forge test --match-test test_UpgradeMarketplaceToV2

# 运行权限测试
$ forge test --match-test test_NonOwnerCannotUpgrade
$ forge test --match-test test_OnlyOwnerCanUpgrade

# 运行功能测试
$ forge test --match-test test_MintAndListNFT
$ forge test --match-test test_BuyNFT
```

#### 详细测试输出
```shell
$ forge test -vv
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

#### 部署 NFT 市场合约
```shell
# 使用 keystore 部署（推荐）
$ forge script script/DeployNFTMarket.s.sol --account <your_account_name> --rpc-url <your_rpc_url> --broadcast

# 使用私钥部署（不推荐）
$ forge script script/DeployNFTMarket.s.sol --rpc-url <your_rpc_url> --private-key <your_private_key> --broadcast
```

#### 部署后更新地址
部署完成后，请将合约地址更新到 README.md 中的相应位置。

#### 升级合约
```shell
# 升级 NFT 合约到 V2
$ cast send <ProxyAdmin地址> "upgradeAndCall(address,address,bytes)" <NFT代理地址> <V2实现地址> "" --account <your_account_name> --rpc-url <your_rpc_url>

# 升级市场合约到 V2  
$ cast send <ProxyAdmin地址> "upgradeAndCall(address,address,bytes)" <市场代理地址> <V2实现地址> "" --account <your_account_name> --rpc-url <your_rpc_url>
```

### Cast

#### 合约交互示例
```shell
# 查看代币信息
$ cast call <Token代理地址> "name()" --rpc-url <your_rpc_url>
$ cast call <Token代理地址> "symbol()" --rpc-url <your_rpc_url>
$ cast call <Token代理地址> "totalSupply()" --rpc-url <your_rpc_url>

# 查看 NFT 信息
$ cast call <NFT代理地址> "name()" --rpc-url <your_rpc_url>
$ cast call <NFT代理地址> "symbol()" --rpc-url <your_rpc_url>

# 查看市场信息
$ cast call <Marketplace代理地址> "nftContract()" --rpc-url <your_rpc_url>
$ cast call <Marketplace代理地址> "tokenContract()" --rpc-url <your_rpc_url>

# 铸造 NFT
$ cast send <NFT代理地址> "mint(address,uint256,string)" <接收地址> <tokenId> <tokenURI> --account <your_account_name> --rpc-url <your_rpc_url>

# 上架 NFT
$ cast send <Marketplace代理地址> "list(uint256,uint256)" <tokenId> <价格> --account <your_account_name> --rpc-url <your_rpc_url>

# 购买 NFT
$ cast send <Marketplace代理地址> "buyNFT(uint256)" <tokenId> --account <your_account_name> --rpc-url <your_rpc_url>
```

#### 通用命令
```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
