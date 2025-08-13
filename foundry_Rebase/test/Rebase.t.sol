// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Rebase} from "../src/Rebase.sol";

contract RebaseTest is Test {
    Rebase public rebase;
    address public owner;
    address public user1;
    address public user2;

    function setUp() public {
        owner = address(this);
        user1 = address(0x1);
        user2 = address(0x2);
        
        rebase = new Rebase();
        
        // Transfer some tokens from owner to test users instead of minting
        rebase.transfer(user1, 1000 * 1e18);
        rebase.transfer(user2, 1000 * 1e18);
    }

    function test_InitialState() public {
        console.log("=== Initial State Test ===");
        console.log("Total Supply:", rebase.totalSupply());
        console.log("Owner Balance:", rebase.balanceOf(owner));
        console.log("User1 Balance:", rebase.balanceOf(user1));
        console.log("User2 Balance:", rebase.balanceOf(user2));
        console.log("Last Rebase Time:", rebase.lastRebaseTime());
        console.log("Current Block Time:", block.timestamp);
        
        // Check if the sum of all balances equals total supply
        uint256 totalBalances = rebase.balanceOf(owner) + rebase.balanceOf(user1) + rebase.balanceOf(user2);
        console.log("Sum of All Balances:", totalBalances);
        console.log("Expected Total Supply: 100,000,000 tokens");
        
        assertEq(rebase.totalSupply(), 100_000_000 * 1e18);
        assertApproxEqRel(rebase.balanceOf(owner), 100_000_000 * 1e18 - 2000 * 1e18, 0.01e18); // Owner transferred 2000 tokens
        assertEq(rebase.balanceOf(user1), 1000 * 1e18);
        assertEq(rebase.balanceOf(user2), 1000 * 1e18);
        assertEq(rebase.lastRebaseTime(), block.timestamp);
        
        // Verify that total balances approximately equal total supply
        assertApproxEqRel(totalBalances, 100_000_000 * 1e18, 0.01e18);
    }

    function test_Transfer() public {
        console.log("=== Transfer Test ===");
        uint256 initialBalance1 = rebase.balanceOf(user1);
        uint256 initialBalance2 = rebase.balanceOf(user2);
        
        console.log("Before Transfer - User1 Balance:", initialBalance1);
        console.log("Before Transfer - User2 Balance:", initialBalance2);
        console.log("Transfer Amount: 100 tokens");
        
        // User1 transfers to User2
        vm.prank(user1);
        rebase.transfer(user2, 100 * 1e18);
        
        uint256 finalBalance1 = rebase.balanceOf(user1);
        uint256 finalBalance2 = rebase.balanceOf(user2);
        
        console.log("After Transfer - User1 Balance:", finalBalance1);
        console.log("After Transfer - User2 Balance:", finalBalance2);
        
        assertEq(finalBalance1, initialBalance1 - 100 * 1e18);
        assertEq(finalBalance2, initialBalance2 + 100 * 1e18);
    }

    function test_Mint() public {
        console.log("=== Mint Test ===");
        uint256 initialSupply = rebase.totalSupply();
        uint256 initialBalance = rebase.balanceOf(user1);
        
        console.log("Before Mint - Total Supply:", initialSupply);
        console.log("Before Mint - User1 Balance:", initialBalance);
        console.log("Mint Amount: 500 tokens");
        
        rebase.mint(user1, 500 * 1e18);
        
        uint256 finalSupply = rebase.totalSupply();
        uint256 finalBalance = rebase.balanceOf(user1);
        
        console.log("After Mint - Total Supply:", finalSupply);
        console.log("After Mint - User1 Balance:", finalBalance);
        
        assertEq(finalSupply, initialSupply + 500 * 1e18);
        assertEq(finalBalance, initialBalance + 500 * 1e18);
    }

    function test_Burn() public {
        console.log("=== Burn Test ===");
        uint256 initialSupply = rebase.totalSupply();
        uint256 initialBalance = rebase.balanceOf(user1);
        
        console.log("Before Burn - Total Supply:", initialSupply);
        console.log("Before Burn - User1 Balance:", initialBalance);
        console.log("Burn Amount: 100 tokens");
        
        rebase.burn(user1, 100 * 1e18);
        
        uint256 finalSupply = rebase.totalSupply();
        uint256 finalBalance = rebase.balanceOf(user1);
        
        console.log("After Burn - Total Supply:", finalSupply);
        console.log("After Burn - User1 Balance:", finalBalance);
        
        assertEq(finalSupply, initialSupply - 100 * 1e18);
        assertEq(finalBalance, initialBalance - 100 * 1e18);
    }

    function test_RebaseAfterOneYear() public {
        console.log("=== Rebase After One Year Test ===");
        uint256 initialSupply = rebase.totalSupply();
        console.log("Before Rebase - Total Supply:", initialSupply);
        console.log("Before Rebase - Current Time:", block.timestamp);
        
        // Fast forward one year
        uint256 newTime = block.timestamp + 365 days;
        vm.warp(newTime);
        console.log("After Warp - New Time:", newTime);
        console.log("After Warp - Current Time:", block.timestamp);
        
        rebase.rebaseYear();
        
        uint256 finalSupply = rebase.totalSupply();
        uint256 expectedSupply = initialSupply * 99 / 100;
        
        console.log("After Rebase - Total Supply:", finalSupply);
        console.log("After Rebase - Expected Supply:", expectedSupply);
        console.log("Reduction Percentage: 1%");
        
        // Total supply should decrease by 1%
        assertEq(finalSupply, expectedSupply);
    }

    function test_RebaseAfterMultipleYears() public {
        console.log("=== Rebase After Multiple Years Test ===");
        uint256 initialSupply = rebase.totalSupply();
        console.log("Before Rebase - Total Supply:", initialSupply);
        console.log("Before Rebase - Current Time:", block.timestamp);
        
        // Fast forward 3 years
        uint256 newTime = block.timestamp + 3 * 365 days;
        vm.warp(newTime);
        console.log("After Warp - New Time:", newTime);
        console.log("After Warp - Current Time:", block.timestamp);
        console.log("Years Forward: 3 years");
        
        rebase.rebaseYear();
        
        uint256 finalSupply = rebase.totalSupply();
        uint256 expectedSupply = initialSupply * 97 / 100;
        
        console.log("After Rebase - Total Supply:", finalSupply);
        console.log("After Rebase - Expected Supply:", expectedSupply);
        console.log("Reduction Percentage: 3%");
        
        // Total supply should decrease by 3% (with some tolerance for precision)
        assertApproxEqRel(finalSupply, expectedSupply, 0.01e18);
    }

    function test_RebaseBeforeOneYear() public {
        console.log("=== Rebase Before One Year Test ===");
        uint256 initialSupply = rebase.totalSupply();
        console.log("Before Rebase - Total Supply:", initialSupply);
        console.log("Before Rebase - Current Time:", block.timestamp);
        
        // Fast forward 6 months
        uint256 newTime = block.timestamp + 180 days;
        vm.warp(newTime);
        console.log("After Warp - New Time:", newTime);
        console.log("After Warp - Current Time:", block.timestamp);
        console.log("Days Forward: 180 days (less than one year)");
        
        rebase.rebaseYear();
        
        uint256 finalSupply = rebase.totalSupply();
        console.log("After Rebase - Total Supply:", finalSupply);
        console.log("Supply Change: No change");
        
        // Total supply should not change (with some tolerance for precision)
        assertApproxEqRel(finalSupply, initialSupply, 0.01e18);
    }

    function test_GetRebaseTime() public {
        console.log("=== Get Rebase Time Test ===");
        uint256 initialRebaseTime = rebase.getRebaseTime();
        console.log("Initial Rebase Time:", initialRebaseTime, "years");
        assertEq(initialRebaseTime, 0);
        
        // Fast forward 2 years
        uint256 newTime = block.timestamp + 2 * 365 days;
        vm.warp(newTime);
        console.log("After Warp - New Time:", newTime);
        console.log("After Warp - Current Time:", block.timestamp);
        console.log("Years Forward: 2 years");
        
        uint256 finalRebaseTime = rebase.getRebaseTime();
        console.log("After Warp Rebase Time:", finalRebaseTime, "years");
        assertEq(finalRebaseTime, 2);
    }

    function test_OnlyOwnerCanMint() public {
        vm.prank(user1);
        vm.expectRevert();
        rebase.mint(user2, 100 * 1e18);
    }

    function test_OnlyOwnerCanBurn() public {
        vm.prank(user1);
        vm.expectRevert();
        rebase.burn(user2, 100 * 1e18);
    }

    function test_OnlyOwnerCanRebase() public {
        vm.warp(block.timestamp + 365 days);
        
        vm.prank(user1);
        vm.expectRevert();
        rebase.rebaseYear();
    }

    function test_TransferToZeroAddress() public {
        vm.prank(user1);
        vm.expectRevert("ERC20: transfer to the zero address");
        rebase.transfer(address(0), 100 * 1e18);
    }

    function test_TransferInsufficientBalance() public {
        vm.prank(user1);
        vm.expectRevert("ERC20: transfer amount exceeds balance");
        rebase.transfer(user2, 2000 * 1e18); // Exceeds balance
    }

    function test_BalanceConsistencyAfterRebase() public {
        console.log("=== Balance Consistency After Rebase Test ===");
        uint256 initialBalance1 = rebase.balanceOf(user1);
        uint256 initialBalance2 = rebase.balanceOf(user2);
        
        console.log("Before Rebase - User1 Balance:", initialBalance1);
        console.log("Before Rebase - User2 Balance:", initialBalance2);
        
        // Fast forward one year and execute rebase
        uint256 newTime = block.timestamp + 365 days;
        vm.warp(newTime);
        console.log("After Warp One Year - Current Time:", newTime);
        
        rebase.rebaseYear();
        
        // User balances should decrease proportionally
        uint256 newBalance1 = rebase.balanceOf(user1);
        uint256 newBalance2 = rebase.balanceOf(user2);
        
        console.log("After Rebase - User1 Balance:", newBalance1);
        console.log("After Rebase - User2 Balance:", newBalance2);
        console.log("User1 Balance Change:", initialBalance1 - newBalance1);
        console.log("User2 Balance Change:", initialBalance2 - newBalance2);
        
        // Balances should decrease by 1% proportionally
        assertApproxEqRel(newBalance1, initialBalance1 * 99 / 100, 0.01e18);
        assertApproxEqRel(newBalance2, initialBalance2 * 99 / 100, 0.01e18);
    }
} 