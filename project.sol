// SPDX-License-Identifier: MIT
//Author: Jenny Shah, Stuti Desai, Arjav Patel
//Deployed contract address in Sepolia Testnet: 0x228ca64fD0198b1E8ab743A080cA8Ce2d7239CC1
//My Sepolia testnet account address: 0xcd428461B5315A73aB6A9De1A9F2939C7Ac8C84f

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract RealEstateToken is ERC20 {
    address public owner;
    AggregatorV3Interface internal priceFeed;

    event TokensBought(address indexed buyer, uint256 amount, uint256 totalPrice);
    event TokensSold(address indexed seller, uint256 amount, uint256 salePrice);

    constructor(string memory name, string memory symbol, address _priceFeed) ERC20(name, symbol) {
        require(_priceFeed != address(0), "Invalid price feed address");
        owner = msg.sender;
        priceFeed = AggregatorV3Interface(_priceFeed);
    }

    function buyToken(uint256 amount) public payable {
        uint256 tokenPrice = getTokenPrice();
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

    function withdraw() public {
        require(msg.sender == owner, "Only owner can withdraw");
        uint256 balance = address(this).balance;
        require(balance > 0, "No balance to withdraw");

        payable(msg.sender).transfer(balance);
    }
}
