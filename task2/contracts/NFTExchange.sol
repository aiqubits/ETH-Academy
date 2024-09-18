// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// ReentrancyGuard 防合约调用重入攻击
contract NFTExchange is ReentrancyGuard {
    struct Order {
        // NFT 持有人
        address owner;
        // 挂单价格
        uint256 price;
    }
    // 生成order 方法 展示订单信息
    mapping(address => mapping(uint256 => Order)) public orders;

    event Listed(address indexed nftAddress, uint256 indexed tokenId, uint256 price);
    event Revoked(address indexed nftAddress, uint256 indexed tokenId);
    event Updated(address indexed nftAddress, uint256 indexed tokenId, uint256 newPrice);
    event Purchased(address indexed nftAddress, uint256 indexed tokenId, address buyer);

    // 卖家挂单NFT list 
    function list(address nftAddress, uint256 tokenId, uint256 price) external {
        IERC721 nft = IERC721(nftAddress);
        require(nft.ownerOf(tokenId) == msg.sender, "Not the owner");
        require(nft.getApproved(tokenId) == address(this) || nft.isApprovedForAll(msg.sender, address(this)), "Not approved");

        orders[nftAddress][tokenId] = Order(msg.sender, price);
        emit Listed(nftAddress, tokenId, price);
    }
    // 卖家撤单NFT revoke
    function revoke(address nftAddress, uint256 tokenId) external {
        require(orders[nftAddress][tokenId].owner == msg.sender, "Not the owner");

        delete orders[nftAddress][tokenId];
        emit Revoked(nftAddress, tokenId);
    }
    // 卖家修改价格NFT update
    function update(address nftAddress, uint256 tokenId, uint256 newPrice) external {
        require(orders[nftAddress][tokenId].owner == msg.sender, "Not the owner");

        orders[nftAddress][tokenId].price = newPrice;
        emit Updated(nftAddress, tokenId, newPrice);
    }
    // 买家购买NFT purchase
    function purchase(address nftAddress, uint256 tokenId) external payable nonReentrant {
        Order storage order = orders[nftAddress][tokenId];
        require(order.owner != address(0), "Order does not exist");
        require(msg.value >= order.price, "Insufficient payment");

        IERC721 nft = IERC721(nftAddress);
        nft.safeTransferFrom(order.owner, msg.sender, tokenId);

        payable(order.owner).transfer(order.price);
        if (msg.value > order.price) {
            payable(msg.sender).transfer(msg.value - order.price);
        }

        delete orders[nftAddress][tokenId];
        emit Purchased(nftAddress, tokenId, msg.sender);
    }
}