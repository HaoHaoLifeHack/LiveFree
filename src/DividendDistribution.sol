// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./RealEstateToken.sol";
import "forge-std/console.sol";

contract DividendDistribution {
    address public admin;
    ERC20 usdc;

    // mapping每個RealEstateToken合約到其分紅資訊
    struct DividendInfo {
        uint256 rentalIncome; // 鏈下房產租金收益
        uint256 capitalGains; // 鏈下房產資本利得
        uint256 tradingFees; // 鏈上Token交易手續費
        uint256 totalDividends;
        mapping(address => uint256) withdrawnDividends; // withdraw log
    }

    mapping(address => DividendInfo) public dividends;

    constructor(address _usdc) {
        admin = msg.sender;
        usdc = ERC20(_usdc);
    }

    modifier onlyOwner() {
        require(msg.sender == admin, "Invalid owner");
        _;
    }

    function updateRentalIncome(
        address tokenAddress,
        uint256 amount
    ) public onlyOwner {
        dividends[tokenAddress].rentalIncome += amount;
        updateTotalDividends(tokenAddress);
    }

    function updateCapitalGains(
        address tokenAddress,
        uint256 amount
    ) public onlyOwner {
        dividends[tokenAddress].capitalGains += amount;
        updateTotalDividends(tokenAddress);
    }

    // 如果實現了鏈上手續費收入
    function updateTradingFees(
        address tokenAddress,
        uint256 amount
    ) public onlyOwner {
        dividends[tokenAddress].tradingFees += amount;
        updateTotalDividends(tokenAddress);
    }

    function updateTotalDividends(address tokenAddress) public {
        DividendInfo storage info = dividends[tokenAddress];
        info.totalDividends =
            info.rentalIncome +
            info.capitalGains +
            info.tradingFees;
    }

    function withdrawDividends(address tokenAddress) public {
        RealEstateToken token = RealEstateToken(tokenAddress);
        uint256 holderBalance = token.balanceOf(msg.sender);
        uint256 totalSupply = token.totalSupply();

        DividendInfo storage info = dividends[tokenAddress];
        uint256 holderDividends = (holderBalance * info.totalDividends) /
            totalSupply;

        holderDividends -= info.withdrawnDividends[msg.sender];
        console.log("msg.sender: ", msg.sender);
        console.log("holderDividends: ", holderDividends);

        require(holderDividends > 0, "No dividends available");

        // 更新已提取的分紅金額
        info.withdrawnDividends[msg.sender] += holderDividends;

        usdc.transfer(msg.sender, holderDividends);
    }
}
