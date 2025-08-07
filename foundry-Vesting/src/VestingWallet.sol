// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Ownable} from "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {ERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {SafeERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

contract VestingWallet is Ownable {
    address public immutable _beneficiary;
    uint256 public immutable _start;
    uint256 public immutable _duration;
    uint256 public immutable _cliff;
    ERC20 public immutable _token;

    uint256 public totalAmount;
    uint256 public _released;

    constructor(address beneficiary_, ERC20 token_) Ownable(beneficiary_) {
        _beneficiary = beneficiary_;
        _cliff = 12 * 30 days;
        _duration =  24 * 30 days;
        _start = block.timestamp;
        _token = token_;
    }

    function deposit(uint256 amount) public {
        if(block.timestamp < start() + cliff()) {
            SafeERC20.safeTransferFrom(ERC20(_token), msg.sender, address(this), amount);
            totalAmount += amount;
        } else {
            revert("VestingWallet: cannot deposit after cliff");
        }
    }

    function start() public view returns (uint256) {
        return _start;
    }

    //cliff 时间 锁仓时长
    function cliff() public view returns (uint256) {
        return _cliff;
    }       

    //发放时长
    function duration() public view returns (uint256) {
        return _duration;
    }

    //锁仓结束时间
    function end() public view returns (uint256) {
        return start() +  cliff() + duration();
    }

    //已释放金额
    function released() public view returns (uint256) {
        return _released;
    }

    //需要的释放金额
    function releaseAmount() public view returns (uint256) {
        if(block.timestamp < start() + cliff()) {
            return 0;
        } else if (block.timestamp >= end()) {
            return totalAmount - released();
        } else {
            uint256 timeElapsed = block.timestamp - start() - cliff();
            uint256 monthsElapsed = timeElapsed / 30 days;
            uint256 totalVested = (totalAmount * monthsElapsed) / 24; // 24个月
            return totalVested - released();
        }
    }

    //释放金额
    function release() public {
        uint256 amount = releaseAmount();
        if(amount > 0) {
            SafeERC20.safeTransfer(ERC20(_token), _beneficiary, amount);
            _released += amount;
        }
    }

    //剩余锁仓金额
    function remainingAmount() public view returns (uint256) {
        if (block.timestamp < start() + cliff()) {
            return totalAmount;
        } else if (block.timestamp >= end()) {
            return 0;
        } else {
            uint256 timeElapsed = block.timestamp - start() - cliff();
            uint256 monthsElapsed = timeElapsed / 30 days;
            uint256 vestedAmount = (totalAmount * monthsElapsed) / 24; // 24个月
            return totalAmount - vestedAmount;
        }
    }
}