// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
    编写一个 TokenBank 合约，可以将自己的 Token 存入到 TokenBank， 和从 TokenBank 取出。

    TokenBank 有两个方法：
    deposit() : 需要记录每个地址的存入数量；
    withdraw（）: 用户可以提取自己的之前存入的 token。

    实现automation:
    用户可以通过 deposit() 存款， 然后使用 ChainLink Automation实现一个自动化任务， 
    自动化任务实现：当 Bank 合约的存款超过 x (可自定义数量)时， 转移一半的存款到指定的地址（如 Owner）。

*/


import {BaseERC20} from "./Token.sol";
import {AutomationCompatibleInterface} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/automation/interfaces/AutomationCompatibleInterface.sol";



//user token.approve(TokenBank.address, amount);

contract TokenBank is AutomationCompatibleInterface {
    mapping(address => uint256) public balances;
    BaseERC20 public token;
    
    address public owner;

    constructor (BaseERC20 _token) {
        token = _token;
        owner = msg.sender;
    }

    function deposit (uint256 amount) public {   
        require(token.transferFrom(msg.sender, address(this), amount), "transferFrom failed");
        balances[msg.sender] += amount;
    }


    function withdraw(uint256 amount) public {       
        require(balances[msg.sender] >= amount, "user's balance not enough");
        require(token.transfer(msg.sender, amount),"transfer failed");     
        balances[msg.sender] -= amount;
    }

    function checkUpkeep(bytes calldata checkData) external view override returns (bool upkeepNeeded, bytes memory performData){
        // 如果checkData长度是20字节，直接转换为地址
        address user;
        if (checkData.length == 20) {
            assembly {
                user := shr(96, calldataload(checkData.offset))
            }
        } else {
            user = abi.decode(checkData, (address));
        }
        upkeepNeeded = balances[user] > 1000;
        return (upkeepNeeded, checkData);
    }

    function performUpkeep(bytes calldata performData) external override {
        // 如果performData长度是20字节，直接转换为地址
        address user;
        if (performData.length == 20) {
            assembly {
                user := shr(96, calldataload(performData.offset))
            }
        } else {
            user = abi.decode(performData, (address));
        }
        if(balances[user] > 1000){
            token.transfer(owner, balances[user] / 2);
            balances[user] -= balances[user] / 2;
        }
    }
}


