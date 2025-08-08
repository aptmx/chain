// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/MemeToken.sol";
import "../src/Proxy.sol";
import "../src/MemeFactory.sol";

contract DeployMemePlatform is Script{

     function run() public {
        vm.startBroadcast();

        // 1. 部署 MemeToken 逻辑合约
        MemeToken memeLogic = new MemeToken();

        // 2. 部署 MemeFactory，传入 MemeToken 逻辑合约地址和 Uniswap Router 地址
        // 可以通过环境变量或命令行参数传入不同网络的地址
        address uniswapV2Router = vm.envAddress("UNISWAP_V2_ROUTER");
        
        MemeFactory factory = new MemeFactory(address(memeLogic), uniswapV2Router);

        console.log("MemeToken logic address:", address(memeLogic));
        console.log("MemeFactory address:", address(factory));

        vm.stopBroadcast();
     }
}