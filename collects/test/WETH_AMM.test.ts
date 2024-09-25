const { expect } = require("chai");
import hre from "hardhat";
import { WETH, MERC20, WETH_AMM } from "../typechain-types";

describe("WETH_AMM", function () {
  let owner: any;
  let addr1, addr2;
  let weth_amm: WETH_AMM;
  let weth: WETH;
  let token1: MERC20;

  beforeEach(async function () {
    [owner, addr1, addr2] = await hre.ethers.getSigners();

    // 部署 WETH 合约
    const WETH = await hre.ethers.getContractFactory("WETH");
    weth = await WETH.deploy();

    // 部署 ERC20 代币合约
    const Token1 = await hre.ethers.getContractFactory("MERC20");
    token1 = await Token1.deploy();

    // 部署 WETH_AMM 合约
    const WETH_AMM_Factory = await hre.ethers.getContractFactory("WETH_AMM");
    weth_amm = await WETH_AMM_Factory.deploy(token1.getAddress());

    // 授权 WETH_AMM 合约使用代币
    await token1.connect(owner).approve(weth_amm.getAddress(), hre.ethers.MaxUint256);
    await weth.connect(owner).approve(weth_amm.getAddress(), hre.ethers.MaxUint256);
  });

  it("Should add liquidity and mint LP tokens", async function () {
    const amount0Desired = hre.ethers.parseEther("10");
    const amount1Desired = hre.ethers.parseEther("20");

    await weth_amm.connect(owner).addLiquidity(amount0Desired, amount1Desired);

    const reserve0 = await weth_amm.reserve0();
    const reserve1 = await weth_amm.reserve1();
    const totalSupply = await weth_amm.totalSupply();

    expect(reserve0).to.equal(amount0Desired);
    expect(reserve1).to.equal(amount1Desired);
    expect(totalSupply).to.be.gt(0);
  });

  it("Should remove liquidity and burn LP tokens", async function () {
    const amount0Desired = hre.ethers.parseEther("10");
    const amount1Desired = hre.ethers.parseEther("20");

    await weth_amm.connect(owner).addLiquidity(amount0Desired, amount1Desired);

    const liquidity = await weth_amm.balanceOf(owner.address);
    await weth_amm.connect(owner).removeLiquidity(liquidity);

    const reserve0 = await weth_amm.reserve0();
    const reserve1 = await weth_amm.reserve1();
    const totalSupply = await weth_amm.totalSupply();

    expect(reserve0).to.equal(0);
    expect(reserve1).to.equal(0);
    expect(totalSupply).to.equal(0);
  });

  it("Should swap tokens", async function () {
    const amount0Desired = hre.ethers.parseEther("10");
    const amount1Desired = hre.ethers.parseEther("20");

    await weth_amm.connect(owner).addLiquidity(amount0Desired, amount1Desired);

    const amountIn = hre.ethers.parseEther("1");
    const amountOutMin = hre.ethers.parseEther("1");

    await weth_amm.connect(owner).swap(amountIn, weth.getAddress(), amountOutMin);

    const balance0 = await weth.balanceOf(owner.address);
    const balance1 = await token1.balanceOf(owner.address);

    expect(balance0).to.be.lt(amount0Desired);
    expect(balance1).to.be.gt(amount1Desired);
  });
});
