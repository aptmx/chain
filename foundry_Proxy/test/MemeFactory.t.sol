
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

    function setUp() public {
        vm.startPrank(deployer);
        implementation = new MemeToken();
        factory = new MemeFactory(address(implementation));
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
        assertEq(meme.balanceOf(user), 1000);

        // 超出 maxSupply 应 revert
        vm.prank(user);
        vm.expectRevert("Exceed supply");
        factory.mintMeme{value: 1 ether}(proxyAddr);
    }
}