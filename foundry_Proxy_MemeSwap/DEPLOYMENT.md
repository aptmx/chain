# MemeFactory 部署说明

## 环境变量设置

在部署之前，需要设置以下环境变量：

### 1. 私钥
```bash
export PRIVATE_KEY="your_private_key_here"
```

### 2. Uniswap V2 Router 地址

根据目标网络设置不同的 Router 地址：

#### 主网 (Ethereum Mainnet)
```bash
export UNISWAP_V2_ROUTER="0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D"
```

#### 测试网
```bash
# Sepolia
export UNISWAP_V2_ROUTER="0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D"

# Goerli  
export UNISWAP_V2_ROUTER="0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D"
```

#### 其他网络
```bash
# BSC
export UNISWAP_V2_ROUTER="0x10ED43C718714eb63d5aA57B78B54704E256024E"

# Polygon
export UNISWAP_V2_ROUTER="0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff"

# Mumbai (Polygon Testnet)
export UNISWAP_V2_ROUTER="0x8954AfA98594b838bda56FE4C12a09D7739D179b"
```

## 部署命令

### 1. 编译合约
```bash
forge build
```

### 2. 部署到测试网 (Sepolia)
```bash
forge script script/Deploy.s.sol --rpc-url $SEPOLIA_RPC_URL --broadcast --verify
```

### 3. 部署到主网
```bash
forge script script/Deploy.s.sol --rpc-url $MAINNET_RPC_URL --broadcast --verify
```

## 网络配置

### Sepolia 测试网
```bash
export SEPOLIA_RPC_URL="https://ethereum-sepolia-rpc.publicnode.com"
export UNISWAP_V2_ROUTER="0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D"
```

### 主网
```bash
export MAINNET_RPC_URL="your_mainnet_rpc_url"
export UNISWAP_V2_ROUTER="0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D"
```

## 验证部署

部署完成后，合约会输出以下信息：
- MemeToken 逻辑合约地址
- MemeFactory 合约地址

请保存这些地址，后续使用 MemeFactory 地址来创建和管理 Meme Token。

## 注意事项

1. **Router 地址验证**: 确保使用的 Router 地址与目标网络匹配
2. **Gas 费用**: 部署需要足够的 ETH 支付 gas 费用
3. **网络选择**: 建议先在测试网部署和测试，确认无误后再部署到主网
4. **私钥安全**: 请妥善保管私钥，不要泄露给他人 