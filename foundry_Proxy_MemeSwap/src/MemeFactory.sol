// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/console.sol";
import "./MemeToken.sol";
import "./Proxy.sol";

import "lib/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "lib/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "lib/v2-core/contracts/interfaces/IUniswapV2Pair.sol";






contract MemeFactory{

    address public immutable implementation; //token 逻辑实现合约
    address public owner; //平台所有者
    mapping(address => address) public memeCreators; //记录合约的创建者

    IUniswapV2Router02 public Router;

    //构造函数，设置逻辑合约和平台owner
    constructor(address _implementation, address _router){
        implementation = _implementation;
        owner = msg.sender;
        Router = IUniswapV2Router02(_router);
    }

    //用代理部署合约
    function deployMeme(
        string memory name,
        string memory symbol,
        uint256 totalSupply,
        uint256 perMint,
        uint256 price
    ) external returns (address proxyAddr){

        // 初始化memetoken合约
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

    //添加流动性
    function addLiquidity(address tokenAddr, uint256 amount) external payable{
        require(msg.sender == owner, "Only owner");
        
        MemeToken meme = MemeToken(tokenAddr);

        //授权 Router 可以转你的token
        meme.approve(address(Router), amount);

        //添加流动性
        Router.addLiquidityETH{value: msg.value}(
            address(meme),
            amount,
            0,
            0,
            address(this),  //接收者
            block.timestamp + 1000
        );
    }

    //get liquidity price
    function getPrice(address tokenAddr) public view returns (uint256){
        address WETH = Router.WETH();
        MemeToken memeToken = MemeToken(tokenAddr);
        address pair = IUniswapV2Factory(Router.factory()).getPair(WETH, address(memeToken));
        require(pair != address(0), "No pair found");

        (uint256 reserve0, uint256 reserve1,) = IUniswapV2Pair(pair).getReserves();
        address token0 = IUniswapV2Pair(pair).token0();
         
         if(token0 == WETH){
            return reserve1 * 1e18 / reserve0;
         }else{
            return reserve0 * 1e18 / reserve1;
         }
    }

    // 获取流动性池信息
    function getLiquidityInfo(address tokenAddr) public view returns (
        address pair,
        uint256 reserve0,
        uint256 reserve1,
        address token0,
        address token1
    ){
        address WETH = Router.WETH();
        MemeToken memeToken = MemeToken(tokenAddr);
        pair = IUniswapV2Factory(Router.factory()).getPair(WETH, address(memeToken));
        
        if(pair != address(0)){
            (reserve0, reserve1,) = IUniswapV2Pair(pair).getReserves();
            token0 = IUniswapV2Pair(pair).token0();
            token1 = IUniswapV2Pair(pair).token1();
        }
    }


    // mintmeme
    function mintMeme(address tokenAddr) external payable {
        MemeToken meme = MemeToken(tokenAddr);
        uint256 cost = meme.mintPrice();
        require(msg.value >= cost, "Insufficient ETH");

        //收费分成
        uint256 toPlatform = cost * 5 /100;
        uint256 toCreator = cost - toPlatform;

        address creator = memeCreators[tokenAddr];
        require(creator != address(0), "Unkown creator");

        //mint token
        meme.mint(address(this));
        uint256 mintAmount = meme.perMint() * 95 /100;
        uint256 platformMemeFee = meme.perMint() * 5 /100;
        meme.transfer(msg.sender, mintAmount);
        meme.transfer(address(this), platformMemeFee);

        //付费给平台
        //(bool sent1, ) = address(this).call{value: toPlatform}("");
        //require(sent1, "Platform payment failed");

        console.log("Platform ethers:", owner.balance);
        console.log("Platform meme :", meme.balanceOf(owner));

        //付费给创建者
        (bool sent2, ) = creator.call{value: toCreator}("");
        require(sent2, "Creator payment failed");

        // 退还多余ETH
        if (msg.value > cost) {
            (bool refundSent, ) = msg.sender.call{value: msg.value - cost}("");
            require(refundSent, "Refund failed");
        }
    }

    //buy meme
    function buyMeme(address tokenAddr) external payable{
        MemeToken meme = MemeToken(tokenAddr);
        uint256 price = getPrice(address(tokenAddr));
        address[] memory path = new address[](2);
        path[0] = Router.WETH();
        path[1] = address(meme);

        console.log("BuyMeme - Token price:", price);
        console.log("BuyMeme - User ETH sent:", msg.value);
        console.log("BuyMeme - User address:", msg.sender);

        if(price > 100e18){
            console.log("BuyMeme - Price is high, executing swap...");
            
            // 获取用户当前代币余额
            uint256 userBalanceBefore = meme.balanceOf(msg.sender);
            console.log("BuyMeme - User balance before swap:", userBalanceBefore);
            
            try Router.swapExactETHForTokens{value: msg.value}(
                0,
                path,
                msg.sender,
                block.timestamp + 1000
            ) returns (uint[] memory amounts) {
                console.log("BuyMeme - Swap successful!");
                console.log("BuyMeme - Amounts[0] (ETH):", amounts[0]);
                console.log("BuyMeme - Amounts[1] (Tokens):", amounts[1]);
                
                uint256 userBalanceAfter = meme.balanceOf(msg.sender);
                console.log("BuyMeme - User balance after swap:", userBalanceAfter);
                console.log("BuyMeme - Tokens received:", userBalanceAfter - userBalanceBefore);
            } catch Error(string memory reason) {
                console.log("BuyMeme - Swap failed with reason:", reason);
                revert("Swap failed");
            } catch {
                console.log("BuyMeme - Swap failed with unknown error");
                revert("Swap failed");
            }
        } else {
            console.log("BuyMeme - Price is too low, no swap executed");
        }
    }

    //接收ETH
    receive() external payable {}
}
