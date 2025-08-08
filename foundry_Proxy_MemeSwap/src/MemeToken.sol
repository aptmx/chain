// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";
// import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";


import "lib/openzeppelin-contracts-upgradeable/contracts/token/ERC20/ERC20Upgradeable.sol";
import "lib/openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import "lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";

/// @custom:oz-upgrades-unsafe-allow constructor
contract MemeToken is Initializable, ERC20Upgradeable, OwnableUpgradeable {

    uint256 public maxSupply;  //最大供应量
    uint256 public perMint;    //每次mint的token数量
    uint256 public mintPrice;  //mint的价格
    address public factory;    //factory合约地址

    

    //initialize 初始化， 由proxy 构造中的 delegatecall 调用 
    function initialize(
        string memory name_,
        string memory symbol_,
        uint256 _totalSupply, //最大供应量
        uint256 _perMint,    // 每次mint的token数量
        uint256 _price,      // mint的价格
        address owner_,
        address factory_
    ) external initializer{
        __ERC20_init(name_, symbol_);
        __Ownable_init(owner_);
        maxSupply = _totalSupply;
        perMint = _perMint;
        mintPrice = _price;
        factory = factory_; //记录factor合约地址
    }

    //factory合约mint
    function mint(address to) external payable {
        require(msg.sender == factory, "only factory can mint");
        require(totalSupply() + perMint <= maxSupply, "Exceed supply");
        _mint(to, perMint);
    }



}