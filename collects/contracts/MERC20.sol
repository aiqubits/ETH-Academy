// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MERC20 is ERC20 {
    constructor() ERC20("MERC20", "MTOKEN") {}
}
