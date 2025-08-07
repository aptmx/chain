// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console2} from "forge-std/Test.sol";
import {VestingWallet} from "../src/VestingWallet.sol";
import {ERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

// 模拟ERC20代币合约
contract MockERC20 is ERC20 {
    constructor() ERC20("Mock Token", "MTK") {
        _mint(msg.sender, 1000000 * 10**decimals());
    }
}

contract VestingWalletTest is Test {
    VestingWallet public vestingWallet;
    MockERC20 public token;
    
    address public beneficiary = address(0x123);
    address public owner = address(this);
    
    uint256 public constant VESTING_AMOUNT = 1000 * 10**18; // 1000 tokens
    uint256 public constant CLIFF_MONTHS = 12;
    uint256 public constant DURATION_MONTHS = 24;
    uint256 public constant CLIFF_DURATION = 12 * 30 days;
    uint256 public constant DURATION_TIME = 24 * 30 days;

    function setUp() public {
        token = new MockERC20();
        vestingWallet = new VestingWallet(beneficiary, token);
        
        // 给受益人一些代币用于测试
        token.transfer(beneficiary, VESTING_AMOUNT);
    }

    function test_Constructor() public {
        assertEq(vestingWallet._beneficiary(), beneficiary);
        assertEq(address(vestingWallet._token()), address(token));
        assertEq(vestingWallet._start(), block.timestamp);
        assertEq(vestingWallet._cliff(), CLIFF_DURATION);
        assertEq(vestingWallet._duration(), DURATION_TIME);
        assertEq(vestingWallet.totalAmount(), 0);
        assertEq(vestingWallet._released(), 0);
    }

    function test_DepositTokens() public {
        vm.startPrank(beneficiary);
        
        uint256 initialBalance = token.balanceOf(beneficiary);
        uint256 initialTotalAmount = vestingWallet.totalAmount();
        
        token.approve(address(vestingWallet), VESTING_AMOUNT);
        vestingWallet.deposit(VESTING_AMOUNT);
        
        assertEq(token.balanceOf(beneficiary), initialBalance - VESTING_AMOUNT);
        assertEq(vestingWallet.totalAmount(), initialTotalAmount + VESTING_AMOUNT);
        
        vm.stopPrank();
    }

    function test_CannotDepositAfterCliff() public {
        vm.startPrank(beneficiary);
        token.approve(address(vestingWallet), VESTING_AMOUNT);
        
        // 快进到锁仓期后
        vm.warp(block.timestamp + CLIFF_DURATION + 1);
        
        vm.expectRevert("VestingWallet: cannot deposit after cliff");
        vestingWallet.deposit(VESTING_AMOUNT);
        
        vm.stopPrank();
    }

    function test_NoReleaseAmountDuringCliff() public {
        vm.startPrank(beneficiary);
        token.approve(address(vestingWallet), VESTING_AMOUNT);
        vestingWallet.deposit(VESTING_AMOUNT);
        vm.stopPrank();
        
        // 在锁仓期内
        vm.warp(block.timestamp + CLIFF_DURATION - 1);
        
        assertEq(vestingWallet.releaseAmount(), 0);
    }

    function test_ReleaseAmountAfterCliff() public {
        vm.startPrank(beneficiary);
        token.approve(address(vestingWallet), VESTING_AMOUNT);
        vestingWallet.deposit(VESTING_AMOUNT);
        vm.stopPrank();
        
        // 快进到锁仓期后6个月
        vm.warp(block.timestamp + CLIFF_DURATION + 6 * 30 days);
        
        // 应该释放 6/24 = 25% 的代币
        uint256 expectedRelease = (VESTING_AMOUNT * 6) / 24;
        assertEq(vestingWallet.releaseAmount(), expectedRelease);
    }

    function test_FullReleaseAmountAfterCompletePeriod() public {
        vm.startPrank(beneficiary);
        token.approve(address(vestingWallet), VESTING_AMOUNT);
        vestingWallet.deposit(VESTING_AMOUNT);
        vm.stopPrank();
        
        // 快进到完全释放期后
        vm.warp(block.timestamp + CLIFF_DURATION + DURATION_TIME + 1);
        
        assertEq(vestingWallet.releaseAmount(), VESTING_AMOUNT);
    }

    function test_ReleaseTokens() public {
        vm.startPrank(beneficiary);
        token.approve(address(vestingWallet), VESTING_AMOUNT);
        vestingWallet.deposit(VESTING_AMOUNT);
        vm.stopPrank();
        
        // 快进到锁仓期后6个月
        vm.warp(block.timestamp + CLIFF_DURATION + 6 * 30 days);
        
        uint256 initialBalance = token.balanceOf(beneficiary);
        uint256 releaseAmount = vestingWallet.releaseAmount();
        uint256 initialReleased = vestingWallet._released();
        
        vm.prank(beneficiary);
        vestingWallet.release();
        
        assertEq(token.balanceOf(beneficiary), initialBalance + releaseAmount);
        assertEq(vestingWallet._released(), initialReleased + releaseAmount);
    }

    function test_NoReleaseBeforeCliff() public {
        vm.startPrank(beneficiary);
        token.approve(address(vestingWallet), VESTING_AMOUNT);
        vestingWallet.deposit(VESTING_AMOUNT);
        vm.stopPrank();
        
        // 在锁仓期内
        vm.warp(block.timestamp + CLIFF_DURATION - 1);
        
        vm.prank(beneficiary);
        vestingWallet.release(); // 应该没有效果，因为releaseAmount为0
        
        assertEq(vestingWallet._released(), 0);
    }

    function test_RemainingAmountDuringCliff() public {
        vm.startPrank(beneficiary);
        token.approve(address(vestingWallet), VESTING_AMOUNT);
        vestingWallet.deposit(VESTING_AMOUNT);
        vm.stopPrank();
        
        // 在锁仓期内
        vm.warp(block.timestamp + CLIFF_MONTHS * 30 days - 1);
        
        assertEq(vestingWallet.remainingAmount(), VESTING_AMOUNT);
    }

    function test_RemainingAmountAfterCliff() public {
        vm.startPrank(beneficiary);
        token.approve(address(vestingWallet), VESTING_AMOUNT);
        vestingWallet.deposit(VESTING_AMOUNT);
        vm.stopPrank();
        
        // 快进到锁仓期后6个月
        vm.warp(block.timestamp + CLIFF_DURATION + 6 * 30 days);
        
        uint256 expectedRemaining = VESTING_AMOUNT - (VESTING_AMOUNT * 6) / 24;
        assertEq(vestingWallet.remainingAmount(), expectedRemaining);
    }

    function test_RemainingAmountAfterCompletePeriod() public {
        vm.startPrank(beneficiary);
        token.approve(address(vestingWallet), VESTING_AMOUNT);
        vestingWallet.deposit(VESTING_AMOUNT);
        vm.stopPrank();
        
        // 快进到完全释放期后
        vm.warp(block.timestamp + CLIFF_DURATION + DURATION_TIME + 1);
        
        assertEq(vestingWallet.remainingAmount(), 0);
    }

    function test_MultipleReleases() public {
        vm.startPrank(beneficiary);
        token.approve(address(vestingWallet), VESTING_AMOUNT);
        vestingWallet.deposit(VESTING_AMOUNT);
        vm.stopPrank();
        
        // 第一次释放：6个月后
        vm.warp(block.timestamp + CLIFF_DURATION + 6 * 30 days);
        uint256 firstRelease = vestingWallet.releaseAmount();
        
        vm.prank(beneficiary);
        vestingWallet.release();
        
        assertEq(vestingWallet._released(), firstRelease);
        
        // 第二次释放：再快进6个月
        vm.warp(block.timestamp + 6 * 30 days);
        uint256 secondRelease = vestingWallet.releaseAmount();
        
        vm.prank(beneficiary);
        vestingWallet.release();
        
        assertEq(vestingWallet._released(), firstRelease + secondRelease);
    }

    function test_TimeFunctions() public {
        uint256 startTime = vestingWallet.start();
        uint256 cliffTime = vestingWallet.cliff();
        uint256 durationTime = vestingWallet.duration();
        uint256 endTime = vestingWallet.end();
        
        assertEq(startTime, block.timestamp);
        assertEq(cliffTime, CLIFF_DURATION);
        assertEq(durationTime, DURATION_TIME);
        assertEq(endTime, startTime + cliffTime + durationTime);
    }

    function test_ReleasableAfterPartialRelease() public {
        vm.startPrank(beneficiary);
        token.approve(address(vestingWallet), VESTING_AMOUNT);
        vestingWallet.deposit(VESTING_AMOUNT);
        vm.stopPrank();
        
        // 快进到锁仓期后6个月
        vm.warp(block.timestamp + CLIFF_DURATION + 6 * 30 days);
        
        uint256 firstRelease = vestingWallet.releaseAmount();
        vm.prank(beneficiary);
        vestingWallet.release();
        
        // 再快进6个月
        vm.warp(block.timestamp + 6 * 30 days);
        
        uint256 secondRelease = vestingWallet.releaseAmount();
        assertEq(secondRelease, (VESTING_AMOUNT * 6) / 24); // 应该是6个月的释放量（从第一次释放后开始计算）
    }

    function test_EdgeCaseExactCliffTime() public {
        vm.startPrank(beneficiary);
        token.approve(address(vestingWallet), VESTING_AMOUNT);
        vestingWallet.deposit(VESTING_AMOUNT);
        vm.stopPrank();
        
        // 快进到精确的锁仓期结束时间
        vm.warp(block.timestamp + CLIFF_DURATION);
        
        uint256 releaseAmount = vestingWallet.releaseAmount();
        assertEq(releaseAmount, 0); // 
    }

    function test_EdgeCaseExactEndTime() public {
        vm.startPrank(beneficiary);
        token.approve(address(vestingWallet), VESTING_AMOUNT);
        vestingWallet.deposit(VESTING_AMOUNT);
        vm.stopPrank();
        
        // 快进到精确的释放期结束时间
        vm.warp(block.timestamp + CLIFF_DURATION + DURATION_TIME);
        
        uint256 releaseAmount = vestingWallet.releaseAmount();
        assertEq(releaseAmount, VESTING_AMOUNT); // 应该释放全部代币
    }

    function test_ReleaseAfterCliffEnd() public {
        vm.startPrank(beneficiary);
        token.approve(address(vestingWallet), VESTING_AMOUNT);
        vestingWallet.deposit(VESTING_AMOUNT);
        vm.stopPrank();
        
        // 快进到锁仓期结束后1秒
        vm.warp(block.timestamp + CLIFF_DURATION + 1);
        
        uint256 releaseAmount = vestingWallet.releaseAmount();
        assertEq(releaseAmount, 0); // 锁仓期结束后，还没有满一个月，不能释放
    }

    function test_ReleaseAfterFirstMonth() public {
        vm.startPrank(beneficiary);
        token.approve(address(vestingWallet), VESTING_AMOUNT);
        vestingWallet.deposit(VESTING_AMOUNT);
        vm.stopPrank();
        
        // 快进到锁仓期结束后1个月
        vm.warp(block.timestamp + CLIFF_DURATION + 30 days);
        
        uint256 releaseAmount = vestingWallet.releaseAmount();
        assertEq(releaseAmount, VESTING_AMOUNT / 24); // 第一个月结束后，可以释放第一个月的量
    }
} 