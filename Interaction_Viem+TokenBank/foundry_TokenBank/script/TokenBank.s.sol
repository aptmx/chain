// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {BaseERC20} from "../src/Token.sol";
import {TokenBank} from "../src/TokenBank.sol";

contract DeployTwo is Script{
    
    BaseERC20 public token;
    TokenBank public tokenbank;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        token = new BaseERC20();
        tokenbank = new TokenBank(BaseERC20(token));

        saveContract("Token", address(token));  // 保存合约地址
        saveContract("TokenBank", address(tokenbank));  // 保存合约地址
        

        vm.stopBroadcast();
    }

   function saveContract(string memory name, address addr) public {
        string memory chainId = vm.toString(block.chainid);

        string memory json1 = "key";
        string memory finalJson = vm.serializeAddress(json1, "address", addr);
        string memory dirPath = string.concat(string.concat("deployments/", name), "_");
        vm.writeJson(finalJson, string.concat(dirPath, string.concat(chainId, ".json")));
    }
}