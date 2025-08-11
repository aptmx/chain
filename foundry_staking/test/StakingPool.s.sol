// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/StakingPool.sol";

/// @notice 简单的KKToken合约，用于测试，带mint权限
contract KKTokenMock is IERC20 {
    string public name = "KKToken";
    string public symbol = "KK";
    uint8 public decimals = 18;
    uint256 public constant TOTAL_SUPPLY = 0;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    function totalSupply() external pure returns (uint256) { return TOTAL_SUPPLY; }

    function transfer(address, uint256) external pure returns (bool) { revert(); }
    function approve(address, uint256) external pure returns (bool) { revert(); }
    function transferFrom(address, address, uint256) external pure returns (bool) { revert(); }

    function mint(address to, uint256 amount) external {
        balanceOf[to] += amount;
        console.log("KKToken minted:", amount, "to:", to);
    }
}

contract StakingPoolTest is Test {
    StakingPool public stakingPool;
    KKTokenMock public kkToken;

    function setUp() public {
        kkToken = new KKTokenMock();
        stakingPool = new StakingPool(address(kkToken), 10 * 1e18);
        console.log("=== Setup Complete ===");
        console.log("KKToken deployed at:", address(kkToken));
        console.log("StakingPool deployed at:", address(stakingPool));
        console.log("Reward per block:", uint256(10 * 1e18));
    }

    function testStakeAndClaim() public {
        console.log("\n=== Starting Test: Stake and Claim ===");
        
        // 给地址1质押 1 ETH
        vm.deal(address(this), 10 ether); // 给测试合约余额
        console.log("Initial balance:", address(this).balance);
        
        stakingPool.stake{value: 1 ether}();
        console.log("Staked 1 ETH");
        console.log("User staked amount:", stakingPool.userStakedAmount(address(this)));
        console.log("Total staked:", stakingPool.totalStaked());

        // 立刻claim奖励 应该是0，因为还没产出区块奖励
        uint256 pending = stakingPool.pendingReward(address(this));
        console.log("Pending reward before blocks:", pending);
        assertEq(pending, 0);

        // 快进10个区块
        vm.roll(block.number + 10);
        console.log("Advanced 10 blocks, current block:", block.number);

        // 计算奖励
        pending = stakingPool.pendingReward(address(this));
        console.log("Pending reward after 10 blocks:", pending);
        assertGt(pending, 0);

        // 检查领取奖励前的KKToken余额
        uint256 kkBalanceBefore = kkToken.balanceOf(address(this));
        console.log("KKToken balance before claim:", kkBalanceBefore);

        // 领取奖励
        stakingPool.claimReward();
        console.log("Claimed reward");

        // 断言 KKToken 收益增加
        uint256 kkBalance = kkToken.balanceOf(address(this));
        console.log("KKToken balance after claim:", kkBalance);
        assertGt(kkBalance, 0);

        // 赎回质押
        uint256 balanceBefore = address(this).balance;
        stakingPool.unstake(1 ether);
        console.log("Unstaked 1 ETH");
        console.log("Balance before unstake:", balanceBefore);
        console.log("Balance after unstake:", address(this).balance);
        console.log("User staked amount after unstake:", stakingPool.userStakedAmount(address(this)));
        console.log("Total staked after unstake:", stakingPool.totalStaked());

        // 余额应该增加了 1 ETH
        assertEq(address(this).balance, 10 ether);
        console.log("=== Test Passed! ===");
    }

    // 添加fallback函数来接收ETH
    receive() external payable {}
}
