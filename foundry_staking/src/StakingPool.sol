// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


/*
    质押挖矿合约：
        1.接受ETH质押
        2.每个区块产生固定的 10 个 KKtoken
        3.按质押数量和质押时间分配
        4.支持stake,unstake,claim 
        5.需要KKToken合约支持 mint(address,uint256)
 */

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IToken is IERC20 {
    function mint(address to, uint256 amount) external;
}



contract StakingPool is ReentrancyGuard, Ownable {
   
    //常量配置
    IToken public immutable KKToken;  //token合约
    uint256 public rewardPerBlock;   //每个区块奖励的token数量
    uint256 private constant REWARD_PRECISION = 1e18;  //精度

    //全局变量
    uint256 public accRewardPerShare; //每单位(wei)质押获得的reward(*RewardPrecision)
    uint256 public lastRewardBlock;  //上次更新accRewardPerToken的区块号
    uint256 public totalStaked;  //总质押量

    //用户信息
    mapping(address => uint256) public userStakedAmount; //用户质押量
    mapping(address => uint256) public userRewardDebt; //用户质押时，区块的accRewardPerToken的值

    //构造函数
    constructor(address _KKToken, uint256 _rewardPerBlock) Ownable(msg.sender){
        KKToken = IToken(_KKToken);
        rewardPerBlock = _rewardPerBlock;
        lastRewardBlock = block.number;  //当前区块号
    }


    //计算用户可提取的奖励
    function pendingReward(address user) public view returns (uint256){
        uint256 _accRewardPerShare = accRewardPerShare;
        uint256 _totalStaked = totalStaked;

        if(block.number > lastRewardBlock && _totalStaked != 0){
            uint256 blocks = block.number - lastRewardBlock;
            uint256 reward = blocks * rewardPerBlock;

            //新增的reward per token
            _accRewardPerShare += (reward * REWARD_PRECISION) / _totalStaked;
        }

        return userStakedAmount[user] * _accRewardPerShare / REWARD_PRECISION - userRewardDebt[user];
    }

    //计算lastRewardBlock到当前快产生的reward,累计到 accRewardPerShare
    function _updateRewardPerShare() internal{
        if(block.number <= lastRewardBlock) return;

        if(totalStaked == 0){
            lastRewardBlock = block.number;
            return;
        }

        //计算区块数与奖励
        uint256 blocks = block.number - lastRewardBlock;
        uint256 reward = blocks * rewardPerBlock;

        accRewardPerShare += (reward * REWARD_PRECISION) / totalStaked;

        //更新 lastRewardBlock
        lastRewardBlock = block.number;
    }

    //用户变动前阶段pending的reward
    function _payPending(address _user) internal{
        uint256 pending = userStakedAmount[_user] * accRewardPerShare / REWARD_PRECISION - userRewardDebt[_user];
        if(pending > 0){
            KKToken.mint(_user, pending); //发放pending的reward
        }
    }

    //质押
    function stake() payable public nonReentrant{
        require(msg.value > 0, "amount must be greater than 0");

        //更新最新累积奖励
        _updateRewardPerShare();

        //如果之前有pending，先发放pending的reward
        _payPending(msg.sender);

        //增加质押量和总量
        userStakedAmount[msg.sender] += msg.value;
        totalStaked += msg.value;

        //更新用户的债务
        userRewardDebt[msg.sender] = userStakedAmount[msg.sender] * accRewardPerShare / REWARD_PRECISION;
    }

    //解质押(部分或者全部都可以)
    function unstake(uint256 amount) external nonReentrant{
        require(amount > 0, "amount must be greater than 0");
        require(userStakedAmount[msg.sender] >= amount, "insufficient balance");

        //更新最新累积奖励
        _updateRewardPerShare();

        //结算并发放奖励
        _payPending(msg.sender);

        //减少质押量和总量
        userStakedAmount[msg.sender] -= amount;
        totalStaked -= amount;

        //更新用户的债务
        userRewardDebt[msg.sender] = userStakedAmount[msg.sender] * accRewardPerShare / REWARD_PRECISION;

        //转账ETH
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "transfer failed");
    }

    //单独领取奖励，不解质押
    function claimReward() external nonReentrant{
        //更新更新累积奖励
        _updateRewardPerShare();

        //结算并发放奖励
        _payPending(msg.sender);

        //更新用户的债务
        userRewardDebt[msg.sender] = userStakedAmount[msg.sender] * accRewardPerShare / REWARD_PRECISION;
    }

    //管理员更改奖励金额
    function setRewardPerBlock(uint256 _rewardPerBlock) external onlyOwner{
        //更新累积奖励
        _updateRewardPerShare();    

        //更新奖励金额
        rewardPerBlock = _rewardPerBlock;
    }

    //接受ETH
    receive() external payable{}
}
