// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract SNFTToken is ERC20 {
    constructor(uint256 initialSupply) ERC20("SNFTToken", "SNFT") {
        _mint(msg.sender, initialSupply);
    }
}
