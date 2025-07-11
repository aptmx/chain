// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
    在 Bank.sol 合约基础之上，编写 IBank 接口及BigBank 合约，使其满足 Bank 实现 IBank;
    BigBank 继承自 Bank， 同时 BigBank 有附加要求：

        1. 要求存款金额 >0.001 ether（用modifier权限控制）
        2. BigBank 合约支持转移管理员

    编写一个 Admin 合约， Admin 合约有自己的 Owner ，同时有一个取款函数 adminWithdraw(IBank bank) ,
    adminWithdraw 中会调用 IBank 接口的 withdraw 方法从而把 bank 合约内的资金转移到 Admin 合约地址。

    BigBank 和 Admin 合约 部署后，把 BigBank 的管理员转移给 Admin 合约地址，模拟几个用户的存款，然后

    Admin 合约的Owner地址调用 adminWithdraw(IBank bank) 把 BigBank 的资金转移到 Admin 地址。

*/

//接口
interface IBank {
    function save(uint amount) external payable;
    function withdraw (address addr) external payable;

}

//继承接口
contract Bank is IBank{
    mapping(address => uint256) public record; //用户地址与用户余额
    address payable public admin; //银行管理员
    address[3] public addrList; //金额前三的地址


    constructor(){
        admin = payable(msg.sender); // admin用户管理员是部署合约的地址
    }


    function save(uint amount) override external payable virtual{
    }

    //withdraw money 从银行合约中取钱
    function withdraw (address addr) override external payable {
        require(addr == admin, "you are not authorized"); //只能是admin
        payable(addr).transfer(address(this).balance);
    }

    // 允许外部地址转钱进银行合约里
    receive() external payable {
        uint amount = msg.value;
        this.save(amount);
    }
}


//合约继承
contract BigBank is Bank{
    modifier minAmount(){
        require(msg.value >= 0.001 ether, "amount must be greater than minAmount");
        _;
    }

    function save(uint amount) override external payable minAmount(){
        require(amount== msg.value, "amount is not equal to msg.value"); 
        record[msg.sender] += amount;
       
        // 数组存储前三金额的地址
        for(uint i=0; i<3; i++){
            if (record[msg.sender] >= record[addrList[i]]){
                if(msg.sender == addrList[i]){ //地址相同
                    return;
                }else {
                    for (uint j=2-i; j>0; j--){
                        addrList[j]=addrList[j-1];
                    }
                    addrList[i]=msg.sender;
                    return;
                }
            }
        }
    }

    //更改本合约的管理员
    function setAdmin(address addr) public returns (address payable){
        admin = payable(addr);
        return admin;
    }
}

//合约调用
contract Admin{
    function adminWithdraw(IBank bank) external payable{
        bank.withdraw(address(this));
    }

    function getBalance() public view returns(uint) {
        return address(this).balance;
    }

    receive() external payable {
    }
}