import { expect } from "chai";
import hre from "hardhat";
import { NFTExchange, MERC721 } from "../typechain-types";
// import { Contract } from "ethers";

// let nft: Contract;
// let nftExchange: Contract;


describe("NFTExchange", function () {
  let nftExchange: NFTExchange;
  let nft: MERC721;
  let owner: any;
  let buyer: any;

  before(async function () {
    const [deployer, user1, user2] = await hre.ethers.getSigners();
    owner = user1;
    buyer = user2;

    // Deploy a mock ERC721 contract
    const ERC721Factory = await hre.ethers.getContractFactory("MERC721");
    nft = await ERC721Factory.deploy();

    // Deploy the NFTExchange contract
    const NFTExchangeFactory = await hre.ethers.getContractFactory("NFTExchange");
    nftExchange = await NFTExchangeFactory.deploy();

    // Mint an NFT to the owner
    await nft.connect(owner).mint(owner.address, 1);
    await nft.connect(owner).setApprovalForAll(nftExchange.address, true);
  });

  it("should list an NFT for sale", async function () {
    const price = hre.ethers.utils.parseEther("1");
    await nftExchange.connect(owner).list(nft.address, 1, price);

    const order = await nftExchange.orders(nft.address, 1);
    expect(order.owner).to.equal(owner.address);
    expect(order.price).to.equal(price);
  });

  it("should revoke a listed NFT", async function () {
    await nftExchange.connect(owner).revoke(nft.address, 1);

    const order = await nftExchange.orders(nft.address, 1);
    expect(order.owner).to.equal(ethers.constants.AddressZero);
    expect(order.price).to.equal(0);
  });

  it("should update the price of a listed NFT", async function () {
    const initialPrice = hre.ethers.utils.parseEther("1");
    const newPrice = hre.ethers.utils.parseEther("2");

    await nftExchange.connect(owner).list(nft.address, 1, initialPrice);
    await nftExchange.connect(owner).update(nft.address, 1, newPrice);

    const order = await nftExchange.orders(nft.address, 1);
    expect(order.price).to.equal(newPrice);
  });

  it("should purchase a listed NFT", async function () {
    const price = hre.ethers.utils.parseEther("1");
    await nftExchange.connect(owner).list(nft.address, 1, price);

    const ownerBalanceBefore = await hre.ethers.provider.getBalance(owner.address);
    const buyerBalanceBefore = await hre.ethers.provider.getBalance(buyer.address);

    await nftExchange.connect(buyer).purchase(nft.address, 1, { value: price });

    const ownerBalanceAfter = await hre.ethers.provider.getBalance(owner.address);
    const buyerBalanceAfter = await hre.ethers.provider.getBalance(buyer.address);

    expect(ownerBalanceAfter).to.equal(ownerBalanceBefore.add(price));
    expect(buyerBalanceAfter).to.equal(buyerBalanceBefore.sub(price));

    const order = await nftExchange.orders(nft.address, 1);
    expect(order.owner).to.equal(hre.ethers.constants.AddressZero);
    expect(order.price).to.equal(0);
  });

  it("should revert if not the owner tries to list an NFT", async function () {
    const price = hre.ethers.utils.parseEther("1");
    await expect(nftExchange.connect(buyer).list(nft.address, 1, price)).to.be.revertedWith("Not the owner");
  });

  it("should revert if not the owner tries to revoke an NFT", async function () {
    const price = hre.ethers.utils.parseEther("1");
    await nftExchange.connect(owner).list(nft.address, 1, price);
    await expect(nftExchange.connect(buyer).revoke(nft.address, 1)).to.be.revertedWith("Not the owner");
  });

  it("should revert if not the owner tries to update an NFT", async function () {
    const price = hre.ethers.utils.parseEther("1");
    await nftExchange.connect(owner).list(nft.address, 1, price);
    await expect(nftExchange.connect(buyer).update(nft.address, 1, price)).to.be.revertedWith("Not the owner");
  });

  it("should revert if the order does not exist during purchase", async function () {
    await expect(nftExchange.connect(buyer).purchase(nft.address, 2, { value: hre.ethers.utils.parseEther("1") })).to.be.revertedWith("Order does not exist");
  });

  it("should revert if the payment is insufficient during purchase", async function () {
    const price = hre.ethers.utils.parseEther("1");
    await nftExchange.connect(owner).list(nft.address, 1, price);
    await expect(nftExchange.connect(buyer).purchase(nft.address, 1, { value: hre.ethers.utils.parseEther("0.5") })).to.be.revertedWith("Insufficient payment");
  });
});
