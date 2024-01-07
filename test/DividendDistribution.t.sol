// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/DividendDistribution.sol";
import "../src/RealEstateToken.sol";
import "../src/Register.sol";

contract DividendDistributionTest is Test {
    DividendDistribution dividendDistribution;
    RealEstateToken realEstateToken;
    Register register;
    address tokenAddress;
    ERC20 usdc;
    address admin;

    function setUp() public {
        admin = makeAddr("admin");
        // 部署 DividendDistribution 合約
        vm.prank(admin);
        dividendDistribution = new DividendDistribution();

        // 模擬一個USDC代幣合約
        usdc = ERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);

        // 部署 Register 合約
        register = new Register();

        // 使用 Register 合約註冊一個新的 RealEstateToken
        string memory ipfsHash = "QmSomeIpfsHash";
        uint256 initialPropertyPrice = 1000 ether;
        uint256 saleDuration = 1 weeks;
        tokenAddress = register.registerProperty(
            ipfsHash,
            initialPropertyPrice,
            saleDuration,
            address(usdc)
        );

        // 取得 RealEstateToken 實例
        realEstateToken = RealEstateToken(tokenAddress);
    }

    function testUpdateRentalIncome() public {
        (uint256 initialRentalIncome, , , ) = dividendDistribution.dividends(
            tokenAddress
        );
        uint256 amountToAdd = 100 ether;

        vm.prank(admin);
        dividendDistribution.updateRentalIncome(tokenAddress, amountToAdd);
        (uint256 newRentalIncome, , , ) = dividendDistribution.dividends(
            tokenAddress
        );

        assertEq(newRentalIncome, initialRentalIncome + amountToAdd);
    }

    function testUpdateCapitalGains() public {
        (, uint256 initialCapitalGains, , ) = dividendDistribution.dividends(
            tokenAddress
        );
        uint256 amountToAdd = 50 ether;

        vm.prank(admin);
        dividendDistribution.updateCapitalGains(tokenAddress, amountToAdd);
        (, uint256 newCapitalGains, , ) = dividendDistribution.dividends(
            tokenAddress
        );
        assertEq(newCapitalGains, initialCapitalGains + amountToAdd);
    }
}
