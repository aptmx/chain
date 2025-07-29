// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "./MemeToken.sol";
import "./Proxy.sol";


contract MemeFactory{

    address public immutable implementation; //token 逻辑实现合约
    address public owner; //平台所有者
    mapping(address => address) public memeCreators; //记录合约的创建者

    //构造函数，设置逻辑合约和平台owner
    constructor(address _implementation){
        implementation = _implementation;
        owner = msg.sender;
    }

    //用代理部署合约
    function deployMeme(
        string memory name,
        string memory symbol,
        uint256 totalSupply,
        uint256 perMint,
        uint256 price
    ) external returns (address proxyAddr){
        bytes memory initData = abi.encodeWithSelector(
            MemeToken.initialize.selector,
            name,
            symbol,
            totalSupply,
            perMint,
            price,
            msg.sender,
            address(this) //传入memefactory地址
        );

        //部署代理合约，Proxy 构造函数中会 delegatecall 调 intialize
        Proxy proxy = new Proxy(implementation, initData);

        //记录memetoken合约的创建者
        memeCreators[address(proxy)] = msg.sender;
        
        return address(proxy);
    }


    // 购买meme
    function mintMeme(address tokenAddr) external payable {
        MemeToken meme = MemeToken(tokenAddr);
        uint256 cost = meme.mintPrice();
        require(msg.value >= cost, "Insufficient ETH");

        //收费分成
        uint256 toPlatform = cost/100;
        uint256 toCreator = cost - toPlatform;

        address creator = memeCreators[tokenAddr];
        require(creator != address(0), "Unkown creator");

        //mint token
        meme.mint(msg.sender);

        //付费
        (bool sent1, ) = owner.call{value: toPlatform}("");
        require(sent1, "Platform payment failed");
        (bool sent2, ) = creator.call{value: toCreator}("");
        require(sent2, "Creator payment failed");

        // 退还多余ETH
        if (msg.value > cost) {
            (bool refundSent, ) = msg.sender.call{value: msg.value - cost}("");
            require(refundSent, "Refund failed");
        }
    }

}
