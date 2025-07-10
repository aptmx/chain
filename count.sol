// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract count{
    uint32 public counter;

    constructor (uint32 x){
        counter = x;
    }

    function get() public view returns (uint32){
        return counter;
    }

    function add(uint32 x) public view returns (uint32) {
        return counter + x;
    }

}