// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract RealEstateToken is ERC20 {
    address public owner;
    AggregatorV3Interface internal priceFeed;
    uint256 public manualPrice;

    event TokensBought(address indexed buyer, uint256 amount, uint256 totalPrice);
    event TokensSold(address indexed seller, uint256 amount, uint256 salePrice);

    constructor(string memory name, string memory symbol, address _priceFeed) ERC20(name, symbol) {
        require(_priceFeed != address(0), "Invalid price feed address");
        owner = msg.sender;
        priceFeed = AggregatorV3Interface(_priceFeed);
    }

    function buyToken(uint256 amount) public payable {
        uint256 tokenPrice;
        if (manualPrice > 0) {
            tokenPrice = manualPrice;
        } else {
            tokenPrice = getTokenPrice();
        }
        uint256 totalPrice = amount * tokenPrice;
        require(msg.value >= totalPrice, "Insufficient funds");

        _mint(msg.sender, amount);
        emit TokensBought(msg.sender, amount, totalPrice);
    }

    function sellToken(uint256 amount) public {
        uint256 tokenPrice = getTokenPrice();
        uint256 salePrice = amount * tokenPrice;
        require(address(this).balance >= salePrice, "Contract balance is insufficient");

        _burn(msg.sender, amount);
        payable(msg.sender).transfer(salePrice);
        emit TokensSold(msg.sender, amount, salePrice);
    }

    function getTokenPrice() public view returns (uint256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        require(price > 0, "Invalid price from price feed");
        return uint256(price);
    }

    function setManualPrice(uint256 price) public {
        require(msg.sender == owner, "Only owner can set manual price");
        require(price > 0, "Invalid manual price");

        manualPrice = price;
    }

    function withdraw() public {
        require(msg.sender == owner, "Only owner can withdraw");
        uint256 balance = address(this).balance;
        require(balance > 0, "No balance to withdraw");

        payable(msg.sender).transfer(balance);
    }

}
