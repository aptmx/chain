// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


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
        // set name,symbol,decimals,totalSupply
        name = "Dragon";
        symbol = "DRG";
        decimals = 18;
        totalSupply = 100000000 * (10 ** decimals);
        balances[msg.sender] = totalSupply;  
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        //balance
        balance = balances[_owner];
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balances[msg.sender]>=_value, "ERC20: transfer amount exceeds balance");
        require(_to != address(0), "address invalid");

        balances[msg.sender] -= _value;
        balances[_to] += _value;

        emit Transfer(msg.sender, _to, _value);  
        return true;   
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {

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

        require(balances[msg.sender] >= _value, "value must be less than your balance");

        allowances[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value); 
        return true; 
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {      
        remaining = allowances[_owner][_spender];
    }

    
}