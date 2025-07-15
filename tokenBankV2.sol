// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "https://github.com/aptmx/chain/blob/main/tokenV2.sol";
import "https://github.com/aptmx/chain/blob/main/tokenBank.sol";

// import "./tokenV2.sol";
// import "./tokenBank.sol";

contract TokenBankV2 is TokenBank, ITokenReceive {
    constructor(BaseERC20 _token) TokenBank(_token){}

    //  回调函数
    function tokensReceived(address _from, uint256 amount) external override {
        require(msg.sender == address(token), "only token contract can call");
        
        balances[_from] += amount;

        totalAmount += amount;
    }

}