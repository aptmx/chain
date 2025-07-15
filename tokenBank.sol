// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
    编写一个 TokenBank 合约，可以将自己的 Token 存入到 TokenBank， 和从 TokenBank 取出。

    TokenBank 有两个方法：

    deposit() : 需要记录每个地址的存入数量；
    withdraw（）: 用户可以提取自己的之前存入的 token。

*/


import "./token.sol";



contract TokenBank{
    mapping(address => uint256) public balances;
    uint256 public totalAmount;
    BaseERC20 public token;

    constructor (BaseERC20 _token) {
        token = _token;
    }

    function deposit (uint256 amount) public {
        
        require(token.transferFrom(msg.sender, address(this), amount), "transferFrom failed");

        //记账
        balances[msg.sender] += amount;
        totalAmount += amount;

    }


    function withdraw(uint256 amount) public {
        
        require(balances[msg.sender] >= amount, "user's balance not enough");
        require(token.transfer(msg.sender, amount),"transfer failed");
       
        //记账
        balances[msg.sender] -= amount;
        totalAmount -= amount;

    }
}
