// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
/*
    编写一个 Bank 合约，实现功能：
    1.	可以通过 Metamask 等钱包直接给 Bank 合约地址存款
    2.	在 Bank 合约记录每个地址的存款金额
    3.	编写 withdraw() 方法，仅管理员可以通过该方法提取资金。
    4.	用数组记录存款金额的前 3 名用户
*/


contract Bank{
    mapping(address => uint256) public record; //用户地址与用户余额
    uint public totalAmount; //银行存入的总余额
    address payable public admin; //银行管理员

    uint public balance; // 合约地址的余额
    address[3] public addrList; //金额前三的地址


    constructor(){
        admin = payable(msg.sender); // admin用户管理员是部署合约的地址
    }

    // save money 存钱
    // record address and amount
    function save(uint amount) public payable{
        require(amount== msg.value, "amount is not equal to msg.value");
        require(msg.value>0, "amount must be great than zero");

        record[msg.sender] += amount;
        totalAmount += amount;

        // 数组存储前三金额的地址
        for(uint i=0; i<3; i++){
            if (record[msg.sender] >= record[addrList[i]]){
                for (uint j=2-i; j>0; j--){
                    addrList[j]=addrList[j-1];
                }
                addrList[i]=msg.sender;
                return;
            }
        }
    }

    //withdraw money 从银行合约中取钱
    function withdraw (uint amount, address payable addr) public payable {
        require(addr == admin, "you are not authorized"); //只能是admin
        require(msg.value == 0, "not save any money"); //没有存钱
        payable(addr).transfer(amount);
        balance -= amount;
    }

    // 允许外部地址转钱进银行合约里
    receive() external payable {
        balance += msg.value;
    }

}