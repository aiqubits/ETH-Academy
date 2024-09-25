// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract InsertionSort {
    function insertionSort(uint[] memory arr) public pure returns (uint[] memory) {
        uint length = arr.length;
        require(length > 0, "Array must not be empty");
        require(length < 1000, "Array length must be less than 1000");

        for (uint i = 1; i < length; i++) {
            uint key = arr[i];
            uint j = i;
            // j >= 1 to avoid index out of bounds
            while (j >= 1 && arr[j-1] > key) {
                arr[j] = arr[j-1];
                j--;
            }
            arr[j] = key;
        }

        return arr;
    }    
}

