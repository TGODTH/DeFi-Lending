// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MarginToken is ERC20 {
    constructor(uint initialSupply) ERC20("MarginToken","MGT"){
        _mint(msg.sender, initialSupply);
    }
    function GetToken(address recipient,uint amount) external {
        _mint(recipient, amount);
    }

    function approve(address owner,address spender, uint256 amount) external  returns (bool) {
        _approve(owner, spender, amount);
        return true;
    }
}