// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";


/*
    ERC20Deflationary token with a rebase mechanism
     - initail supply: 100,000,000 tokens (18 decimals)
     - Each year, total supply is reduced by 1%
     - balanceOf() auto-reflects rebases

    - gonPerFragment 缩放
    - fragment 用户看到的余额
    - reabse时调整 gonsPerFragment
*/

contract Rebase is ERC20, Ownable {

    //constants
    uint256 public constant INITIAL_FRAGMENTS_SUPPLY = 100_000_000 * 1e18; 
    uint256 public constant TOTAL_GONS = type(uint256).max / 1e10 * 1e10;
    
    //variables
    uint256 private _gonsPerFragment; //缩放因子
    uint256 private _totalSupplyFragment; //对外展示的总供应量
    mapping(address => uint256) private _gonBalances; //账户的gond余额

    uint256 public lastRebaseTime; //上次rebase时间
    uint256 private _epoch; //rebase次数

    //events
    event rebase(uint256 indexed epoch, uint256 totalSupply);

    constructor() ERC20("Rebase", "RB") Ownable(msg.sender) {
      //调整精度
      uint256 adjustedTotalGons = TOTAL_GONS - (TOTAL_GONS % INITIAL_FRAGMENTS_SUPPLY);
      _gonsPerFragment = adjustedTotalGons/INITIAL_FRAGMENTS_SUPPLY; //计算初始缩放因子

      _totalSupplyFragment = INITIAL_FRAGMENTS_SUPPLY;

      //初始化owner的gond余额
      _gonBalances[owner()] = adjustedTotalGons;

      lastRebaseTime = block.timestamp;

      emit rebase(_epoch, _totalSupplyFragment);
    }

    function totalSupply() public view override returns (uint256) {
      return _totalSupplyFragment;
    }

    function balanceOf(address account) public view override returns (uint256) {
      return _gonBalances[account] / _gonsPerFragment;
    }

    function _transfer(address from, address to, uint256 amount) internal override {
        require(to != address(0), "ERC20: transfer to the zero address");
        uint256 gonsAmount = amount * _gonsPerFragment;

        require(_gonBalances[from] >= gonsAmount, "ERC20: transfer amount exceeds balance");

        _gonBalances[from] -= gonsAmount;
        _gonBalances[to] += gonsAmount;
        emit Transfer(from, to, amount);
    }

    //mint
    function mint(address to, uint256 amount) external onlyOwner {
      uint256 gonsAmount = amount * _gonsPerFragment;
      _gonBalances[to] += gonsAmount;
      _totalSupplyFragment += amount;
      emit Transfer(address(0), to, amount);
    }

    //burn
    function burn(address from, uint256 amount) external onlyOwner {
      uint256 gonsAmount = amount * _gonsPerFragment;
      _gonBalances[from] -= gonsAmount;
      _totalSupplyFragment -= amount;
      emit Transfer(from, address(0), amount);
    }

    //rebase
    function rebaseYear() external onlyOwner returns (uint256) {
        uint256 elapsed = block.timestamp - lastRebaseTime;
        uint256 yearsElapsed = elapsed / 365 days;
        if(yearsElapsed == 0) {
            return _totalSupplyFragment;
        }

        uint256 newSupply = _totalSupplyFragment;

        for(uint256 i = 0; i < yearsElapsed; i++) {
            newSupply = newSupply * 99 / 100;  //减少1%
            _epoch++;
            emit rebase(_epoch, newSupply);
        }

        _totalSupplyFragment = newSupply;
        
        //调整缩放因子
        uint256 adjustedTotalGons = TOTAL_GONS - (TOTAL_GONS % _totalSupplyFragment);
        _gonsPerFragment = adjustedTotalGons / _totalSupplyFragment;

        //更新lastRebaseTime
        lastRebaseTime += yearsElapsed * 365 days;
        return _totalSupplyFragment;
    }

    //计算rebase时间
    function getRebaseTime() public view returns (uint256) {
        return (block.timestamp - lastRebaseTime) / 365 days;
    }
}
