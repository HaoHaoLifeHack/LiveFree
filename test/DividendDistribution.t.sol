// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
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
    address investor;
    address otherInvestor;

    function setUp() public {
        string memory rpc = vm.envString("MAINNET_RPC_URL");
        // MAINNET_RPC_URL
        // SEPOLIA_RPC_URL
        vm.createSelectFork(rpc, 17465000);
        // Mainnet: 17465000
        // Sepolia: 2515638
        admin = makeAddr("admin");
        investor = makeAddr("investor");
        otherInvestor = makeAddr("otherInvestor");
        usdc = ERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);

        // 部署 DividendDistribution 合約
        vm.prank(admin);
        dividendDistribution = new DividendDistribution(address(usdc));

        // 部署 Register 合約
        register = new Register();

        // 使用 Register 合約註冊一個新的 RealEstateToken
        string memory ipfsHash = "QmSomeIpfsHash";
        uint256 initialPropertyPrice = 1000000e6;
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
        uint256 amountToAdd = 10 ether;

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
        uint256 amountToAdd = 5 ether;

        vm.prank(admin);
        dividendDistribution.updateCapitalGains(tokenAddress, amountToAdd);
        (, uint256 newCapitalGains, , ) = dividendDistribution.dividends(
            tokenAddress
        );
        assertEq(newCapitalGains, initialCapitalGains + amountToAdd);
    }

    function testUpdateTradingFees() public {
        (, , uint256 initialTradingFees, ) = dividendDistribution.dividends(
            tokenAddress
        );
        uint256 amountToAdd = 5 ether;

        vm.prank(admin);
        dividendDistribution.updateTradingFees(tokenAddress, amountToAdd);
        (, , uint256 newTradingFees, ) = dividendDistribution.dividends(
            tokenAddress
        );
        assertEq(newTradingFees, initialTradingFees + amountToAdd);
    }

    function testWithdrawDividends() public {
        uint256 currentDividends = addDivends();
        uint256 initialBalance = usdc.balanceOf(otherInvestor);
        uint256 retAmount = 10000e6; // 0.01 share

        // 為測試帳戶分配RET
        realEstateToken.transfer(otherInvestor, retAmount);

        // 模擬分紅提款
        vm.prank(otherInvestor);
        dividendDistribution.withdrawDividends(tokenAddress);

        uint256 finalBalance = usdc.balanceOf(otherInvestor);

        // 驗證提取後餘額增加
        assertEq(
            finalBalance,
            (initialBalance + (retAmount * currentDividends)) /
                realEstateToken.totalSupply(),
            "Dividend withdrawal failed"
        );
    }

    function addDivends() private returns (uint256) {
        deal(address(usdc), admin, 100000e6);
        vm.startPrank(admin);
        usdc.transfer(address(dividendDistribution), 100000e6);
        uint256 amountToAdd = 10000e6;
        dividendDistribution.updateRentalIncome(tokenAddress, amountToAdd);
        dividendDistribution.updateCapitalGains(tokenAddress, amountToAdd);
        dividendDistribution.updateTradingFees(tokenAddress, amountToAdd);
        vm.stopPrank();
        return amountToAdd * 3;
    }
}
