# VestingWallet 部署指南

## 合约功能
- **受益人**: 指定锁仓代币的接收者
- **锁仓期**: 12个月，期间无法释放任何代币
- **释放期**: 24个月，从第13个月开始线性释放，每月释放 1/24 的代币
- **代币**: 支持任意ERC20代币

## 部署步骤

### 1. 环境配置
创建 `.env` 文件并设置以下环境变量：
```bash
```

### 2. 编译合约
```bash
forge build
```

### 3. 部署合约
```bash
forge script script/DeployVesting.s.sol --rpc-url <RPC_URL> --broadcast --verify
```

### 4. 验证部署
部署成功后，脚本会输出：
- 合约地址
- 受益人地址
- 代币地址
- 开始时间
- 锁仓期和释放期配置

## 使用流程

### 1. 存入代币
受益人调用 `deposit(amount)` 函数存入代币：
```solidity
// 首先需要授权
token.approve(vestingWalletAddress, amount);
// 然后存入
vestingWallet.deposit(amount);
```

### 2. 查看锁仓状态
```solidity
// 查看总锁仓金额
uint256 total = vestingWallet.totalAmount();
// 查看已释放金额
uint256 released = vestingWallet.released();
// 查看当前可释放金额
uint256 releasable = vestingWallet.releaseAmount();
```

### 3. 释放代币
受益人调用 `release()` 函数领取已释放的代币：
```solidity
vestingWallet.release();
```

## 时间线示例

假设在2024年1月1日部署：
- **2024年1月1日 - 2024年12月31日**: 锁仓期，无法释放任何代币
- **2025年1月1日**: 开始线性释放
- **2025年1月1日**: 可释放 1/24 的代币
- **2025年2月1日**: 可释放 2/24 的代币
- **...**
- **2026年12月31日**: 可释放全部代币

## 安全注意事项

1. **私钥安全**: 确保私钥安全存储，不要提交到代码仓库
2. **地址验证**: 部署前仔细检查受益人地址和代币地址
3. **测试网络**: 建议先在测试网络部署和测试
4. **权限管理**: 合约拥有者可以调用紧急提取功能

## 合约函数说明

| 函数名 | 功能 | 调用者 |
|--------|------|--------|
| `deposit(amount)` | 存入代币 | 受益人 |
| `release()` | 释放代币 | 受益人 |
| `releaseAmount()` | 查看可释放金额 | 任何人 |
| `remainingAmount()` | 查看剩余锁仓金额 | 任何人 |
| `start()` | 查看开始时间 | 任何人 |
| `end()` | 查看结束时间 | 任何人 | 