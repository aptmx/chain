// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITokenReceive {
    function tokensReceived(address from, uint256 amount) external;
    function tokensReceived(address from, uint256 amount, uint256 tokenId) external;
}

contract BaseERC20 {
    string public name; 
    string public symbol; 
    uint8 public decimals; 

    uint256 public totalSupply; 

    mapping (address => uint256) balances; 

    mapping (address => mapping (address => uint256)) allowances; 

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor() {
        // write your code here
        // set name,symbol,decimals,totalSupply
        name = "BaseERC20";
        symbol = "BERC20";
        decimals = 18;
        totalSupply = 100000000 * (10 ** decimals);
        balances[msg.sender] = totalSupply;  
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        // write your code here
        balance = balances[_owner];
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        // write your code here
        require(balances[msg.sender]>=_value, "ERC20: transfer amount exceeds balance");
        require(_to != address(0), "address invalid");

        balances[msg.sender] -= _value;
        balances[_to] += _value;

        emit Transfer(msg.sender, _to, _value);  
        return true;   
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        // write your code here
        require(balances[_from] >= _value, "ERC20: transfer amount exceeds balance");
        require(allowances[_from][msg.sender] >= _value, "ERC20: transfer amount exceeds allowance");
        require(_to != address(0), "address invalid");

        balances[_from] -= _value;
        balances[_to] += _value;
        
        allowances[_from][msg.sender] -= _value;

        emit Transfer(_from, _to, _value); 
        return true; 
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        // write your code here
        require(balances[msg.sender] >= _value, "value must be less than your balance");

        allowances[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value); 
        return true; 
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {   
        // write your code here     
        remaining = allowances[_owner][_spender];
    }

    //扩展
    function transferWithCallback(address _to, uint256 amount) public {
        require(transfer(_to, amount), "transer failed");

        if(isContract(_to)){
           ITokenReceive(_to).tokensReceived(msg.sender, amount);
        }
    }

    //判断合约地址
    function isContract(address _to) internal view returns (bool){
        return _to.code.length > 0;
    } 

    //扩展用户回调买NFT
     function transferWithCallback(address _to, uint256 price, uint256 tokenId) public {
        require(transfer(_to, price), "transfer failed");

        if(isContract(_to)){
           ITokenReceive(_to).tokensReceived(msg.sender, price, tokenId);
        }
    }
    
}