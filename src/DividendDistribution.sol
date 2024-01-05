// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./RealEstateToken.sol";

contract DividendDistribution {
    address public admin;

    // mapping每個RealEstateToken合約到其分紅信息
    struct DividendInfo {
        uint256 rentalIncome; // 鏈下房產租金收益
        uint256 capitalGains; // 鏈下房產資本利得
        uint256 tradingFees; // 鏈上Token交易手續費
        uint256 totalDividends;
    }

    mapping(address => DividendInfo) public dividends;

    constructor() {
        admin = msg.sender;
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
    }

    function updateCapitalGains(
        address tokenAddress,
        uint256 amount
    ) public onlyOwner {
        dividends[tokenAddress].capitalGains += amount;
    }

    // 如果實現了鏈上手續費收入
    function updateTradingFees(address tokenAddress, uint256 amount) public {
        dividends[tokenAddress].tradingFees += amount;
    }

    function withdrawDividends(address tokenAddress) public {
        RealEstateToken token = RealEstateToken(tokenAddress);
        uint256 holderBalance = token.balanceOf(msg.sender);
        uint256 totalSupply = token.totalSupply();

        DividendInfo storage info = dividends[tokenAddress];
        uint256 holderDividends = (holderBalance / totalSupply) *
            info.totalDividends;

        require(holderDividends > 0, "No dividends available");
        // 更新已分發的分紅金額
        info.totalDividends -= holderDividends;
        payable(msg.sender).transfer(holderDividends);
    }
}
