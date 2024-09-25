const { expect } = require("chai");
import hre from "hardhat";
import { WETH } from "../typechain-types";

describe("WETH", function () {
  // let WETH;
  let weth: WETH;
  let owner;
  let addr1: any;
  let addr2;
  let addrs;

  before(async function () {
    // Get the ContractFactory and Signers here.
    const WETH = await hre.ethers.getContractFactory("WETH");
    [owner, addr1, addr2, ...addrs] = await hre.ethers.getSigners();

    // Deploy the WETH contract
    weth = await WETH.deploy();
  });

  describe("Deployment", function () {
    it("Should set the right name and symbol", async function () {
      expect(await weth.name()).to.equal("Wrapped Ether");
      expect(await weth.symbol()).to.equal("WETH");
    });
  });

  describe("Deposit", function () {
    it("Should mint WETH when ETH is deposited", async function () {
      const depositAmount = hre.ethers.parseEther("1");
      await weth.connect(addr1).deposit({ value: depositAmount });
      expect(await weth.balanceOf(addr1.address)).to.equal(depositAmount);
    });

    it("Should handle direct ETH transfers", async function () {
      const transferAmount = hre.ethers.parseEther("1");
      await addr1.sendTransaction({ to: weth.getAddress(), value: transferAmount });
      console.log(await weth.balanceOf(addr1.address));
      expect(await weth.balanceOf(addr1.address)).to.equal(transferAmount + transferAmount);
    });
  });

  describe("Withdraw", function () {
    it("Should burn WETH and send ETH back to the user", async function () {
      console.log(await weth.balanceOf(addr1.address)); // 2
      const depositAmount = hre.ethers.parseEther("2");
      await weth.connect(addr1).deposit({ value: depositAmount });
      console.log(await weth.balanceOf(addr1.address));  // 4
      const initialBalance = await hre.ethers.provider.getBalance(addr1.address);
      console.log("initialBalance", initialBalance);
      const withdrawAmount = hre.ethers.parseEther("1");
      await weth.connect(addr1).withdraw(withdrawAmount);
      console.log(await weth.balanceOf(addr1.address)); // 3
      expect(await weth.balanceOf(addr1.address)).to.equal(depositAmount + depositAmount - withdrawAmount);
      const finalBalance = await hre.ethers.provider.getBalance(addr1.address);
      console.log("finalBalance", finalBalance);
      expect(finalBalance).to.be.closeTo(initialBalance + withdrawAmount, 100000000000000); // Account for gas costs
    });

    it("Should revert if the user does not have enough WETH", async function () {
      const withdrawAmount = hre.ethers.parseEther("4");
      console.log(await weth.balanceOf(addr1.address)); // 3
      await expect(weth.connect(addr1).withdraw(withdrawAmount)).to.be.revertedWith("Insufficient balance");
    });
  });
});
