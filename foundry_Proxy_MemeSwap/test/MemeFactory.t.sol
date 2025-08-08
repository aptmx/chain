
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/MemeToken.sol";
import "../src/Proxy.sol";
import "../src/MemeFactory.sol";

contract MemeFactoryTest is Test {
    MemeToken implementation;
    MemeFactory factory;
    address deployer = address(0x1234);
    address user = address(0x5678);

    MockUniswapRouter mockRouter;
    MockUniswapFactory mockFactory;
    
    function setUp() public {
        vm.startPrank(deployer);
        implementation = new MemeToken();
        
        // Deploy mock contracts for testing
        mockRouter = new MockUniswapRouter();
        mockFactory = new MockUniswapFactory();
        
        // Set the factory address in the router
        mockRouter.setFactory(address(mockFactory));
        
        factory = new MemeFactory(address(implementation), address(mockRouter));
        vm.stopPrank();
    }

    function testDeployAndMint() public {
        vm.startPrank(deployer);
        address proxyAddr = factory.deployMeme(
            "TestToken",
            "TTK",
            1000,   // maxSupply
            100,    // perMint
            1 ether // mintPrice
        );
        vm.stopPrank();

        MemeToken meme = MemeToken(proxyAddr);
        assertEq(meme.maxSupply(), 1000);
        assertEq(meme.perMint(), 100);
        assertEq(meme.mintPrice(), 1 ether);

        // 用户首次 mint
        vm.deal(user, 20 ether); // 足够多
        for (uint256 i = 0; i < 10; i++) {
            vm.prank(user);
            factory.mintMeme{value: 1 ether}(proxyAddr);
            
        }
        assertEq(meme.balanceOf(user), 950); // 10次mint，每次95个代币
        assertEq(meme.balanceOf(address(factory)), 50); // 10次mint，每次5个代币留在factory
        assertEq(address(factory).balance, 0.5 ether); // 10次mint，每次0.05 ETH留在factory
    
        //超出 maxSupply 应 revert
        vm.prank(user);
        vm.expectRevert("Exceed supply");
        factory.mintMeme{value: 1 ether}(proxyAddr);

        vm.stopPrank();
        
        //跳过流动性测试，因为需要真实的 Uniswap Router
        vm.startPrank(deployer);
        factory.addLiquidity{value: 0.5 ether}(address(meme), 50 ether);
        vm.stopPrank();
    }

    // 测试获得价格
    function testGetPrice() public {
        vm.startPrank(deployer);
        address proxyAddr = factory.deployMeme(
            "TestToken",
            "TTK",
            1000,   // maxSupply
            100,    // perMint
            1 ether // mintPrice
        );
        vm.stopPrank();

        MemeToken meme = MemeToken(proxyAddr);
        
        // 设置mock pair
        MockUniswapPair mockPair = new MockUniswapPair(
            address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2), // WETH
            address(meme)
        );
        
        // 设置reserves: 1000 WETH, 1000000 tokens (价格 = 1000 tokens per ETH)
        mockPair.setReserves(1000e18, 1000000e18);
        mockFactory.setPair(
            address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2), // WETH
            address(meme),
            address(mockPair)
        );
        
        // 测试获取价格
        uint256 price = factory.getPrice(address(meme));
        console.log("Token price:", price);
        
        // 验证价格计算 (1000000e18 / 1000e18 = 1000e18)
        assertEq(price, 1000e18, "Price calculation incorrect");
    }

    // 测试买meme (价格 > 100e18 时)
    function testBuyMemeWhenPriceHigh() public {
        vm.startPrank(deployer);
        address proxyAddr = factory.deployMeme(
            "TestToken",
            "TTK",
            1000,   // maxSupply
            100,    // perMint
            1 ether // mintPrice
        );
        vm.stopPrank();

        MemeToken meme = MemeToken(proxyAddr);
        
        // 设置mock pair with high price (> 100e18)
        MockUniswapPair mockPair = new MockUniswapPair(
            address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2), // WETH
            address(meme)
        );
        
        // 设置reserves: 1 WETH, 200000 tokens (价格 = 200000 tokens per ETH > 100e18)
        mockPair.setReserves(1e18, 200000e18);
        mockFactory.setPair(
            address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2), // WETH
            address(meme),
            address(mockPair)
        );
        
        // 重置swap标志
        mockRouter.resetSwapFlag();
        
        // 用户购买meme
        vm.startPrank(user);
        vm.deal(user, 10 ether);
        
        // 测试buyMeme函数是否被正确调用（不revert）
        factory.buyMeme{value: 1 ether}(address(meme));
        
        // 验证swap函数被调用
        assertTrue(mockRouter.swapCalled(), "swapExactETHForTokens should be called when price is high");
        assertEq(mockRouter.lastSwapValue(), 1 ether, "Swap value should match input value");
        assertEq(mockRouter.lastSwapTo(), user, "Swap should be to the user");
        
        console.log("user.balance", user.balance);
        console.log("meme.balanceOf(user)", meme.balanceOf(user));
        console.log("buyMeme function executed successfully and swap was called");
        vm.stopPrank();
    }

    // 测试买meme (价格 <= 100e18 时，不应该执行swap)
    function testBuyMemeWhenPriceLow() public {
        vm.startPrank(deployer);
        address proxyAddr = factory.deployMeme(
            "TestToken",
            "TTK",
            1000,   // maxSupply
            100,    // perMint
            1 ether // mintPrice
        );
        vm.stopPrank();

        MemeToken meme = MemeToken(proxyAddr);
        
        // 设置mock pair with low price (<= 100e18)
        MockUniswapPair mockPair = new MockUniswapPair(
            address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2), // WETH
            address(meme)
        );
        
        // 设置reserves: 1000 WETH, 50000 tokens (价格 = 50 tokens per ETH <= 100e18)
        mockPair.setReserves(1000e18, 50000e18);
        mockFactory.setPair(
            address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2), // WETH
            address(meme),
            address(mockPair)
        );
        
        // 重置swap标志
        mockRouter.resetSwapFlag();
        
        // 用户尝试购买meme
        vm.startPrank(user);
        vm.deal(user, 10 ether);
        
        uint256 initialBalance = meme.balanceOf(user);
        factory.buyMeme{value: 1 ether}(address(meme));
        uint256 finalBalance = meme.balanceOf(user);
        
        // 验证用户没有获得代币 (因为价格太低)
        assertEq(finalBalance, initialBalance, "User should not receive tokens when price is low");
        vm.stopPrank();
    }
}

// Mock Uniswap Router for testing
contract MockUniswapRouter {
    address public WETH = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    address public factory;
    
    // 添加一个标志来跟踪是否调用了 swapExactETHForTokens
    bool public swapCalled = false;
    uint256 public lastSwapValue = 0;
    address public lastSwapTo = address(0);
    
    function setFactory(address _factory) external {
        factory = _factory;
    }
    
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity) {
        // Mock implementation - just return the input values
        return (amountTokenDesired, msg.value, 1000);
    }
    
    function getAmountsOut(
        uint amountIn,
        address[] calldata path
    ) external pure returns (uint[] memory amounts) {
        amounts = new uint[](2);
        amounts[0] = amountIn;
        amounts[1] = 1000; // Mock token amount
        return amounts;
    }
    
    function swapExactETHForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts) {
        // 记录调用信息
        swapCalled = true;
        lastSwapValue = msg.value;
        lastSwapTo = to;
        
        amounts = new uint[](2);
        amounts[0] = msg.value;
        amounts[1] = 1000; // Mock token amount
        
        // Mock token transfer to the user
        // In a real scenario, the router would have tokens to transfer
        // For testing purposes, we'll just simulate the swap
        
        return amounts;
    }
    
    // 重置标志的函数
    function resetSwapFlag() external {
        swapCalled = false;
        lastSwapValue = 0;
        lastSwapTo = address(0);
    }
    
    receive() external payable {}
}

// Mock Uniswap Factory for testing
contract MockUniswapFactory {
    mapping(address => mapping(address => address)) public pairs;
    
    function getPair(address tokenA, address tokenB) external view returns (address pair) {
        return pairs[tokenA][tokenB];
    }
    
    function setPair(address tokenA, address tokenB, address pair) external {
        pairs[tokenA][tokenB] = pair;
        pairs[tokenB][tokenA] = pair;
    }
}

// Mock Uniswap Pair for testing
contract MockUniswapPair {
    address public token0;
    address public token1;
    uint112 public reserve0;
    uint112 public reserve1;
    
    constructor(address _token0, address _token1) {
        token0 = _token0;
        token1 = _token1;
    }
    
    function getReserves() external view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast) {
        return (reserve0, reserve1, uint32(block.timestamp));
    }
    
    function setReserves(uint112 _reserve0, uint112 _reserve1) external {
        reserve0 = _reserve0;
        reserve1 = _reserve1;
    }
}