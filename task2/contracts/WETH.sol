// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract WETH is ERC20 {
    constructor() ERC20("Wrapped Ether", "WETH") {}

    // Function to deposit ETH and mint WETH
    function deposit() public payable {
        _mint(msg.sender, msg.value);
    }

    // Function to withdraw ETH by burning WETH
    function withdraw(uint256 amount) public {
        require(balanceOf(msg.sender) >= amount, "Insufficient balance");
        _burn(msg.sender, amount);
        payable(msg.sender).transfer(amount);
    }

    // Fallback function to handle direct ETH transfers
    receive() external payable {
        deposit();
    }
}
