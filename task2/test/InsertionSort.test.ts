import { InsertionSort } from "../typechain-types";
import { expect } from "chai";
import hre from "hardhat";

describe("InsertionSort", function () {
  let insertionSort: InsertionSort;

  before(async function () {
    const InsertionSortFactory = await hre.ethers.getContractFactory("InsertionSort");
    insertionSort = await InsertionSortFactory.deploy();
  });

  it("should sort an array of numbers", async function () {
    const unsortedArray = [5, 3, 8, 4, 2];
    const expectedSortedArray = [2, 3, 4, 5, 8];

    const sortedArray = await insertionSort.insertionSort(unsortedArray);
    expect(sortedArray).to.deep.equal(expectedSortedArray);
  });

  it("should throw an error if the array is empty", async function () {
    const emptyArray: number[] = [];

    await expect(insertionSort.insertionSort(emptyArray)).to.be.revertedWith("Array must not be empty");
  });

  it("should throw an error if the array length is greater than 999", async function () {
    const largeArray = Array.from({ length: 1000 }, (_, i) => i + 1);

    await expect(insertionSort.insertionSort(largeArray)).to.be.revertedWith("Array length must be less than 1000");
  });
});
