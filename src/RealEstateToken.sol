// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "v2-core/interfaces/IUniswapV2Factory.sol";
import "./TradeController.sol";

contract RealEstateToken is ERC20 {
    TradeController tradeController;
    address public propertyOwner;
    uint256 public totalRealEstateValue; // 房屋總市值，以美元表示的最小單位
    uint256 public soldTokens; // track sold tokens
    uint256 public saleEndTime;
    bool public saleEnded;

    uint256 public tokenPrice = 1e6; // Token initial price，1 token = 1 u

    constructor() ERC20("RealEstateToken", "RET") {
        propertyOwner = msg.sender;
    }

    function initialize(
        uint256 _initialPropertyPrice,
        uint256 _saleDuration
    ) public {
        require(msg.sender == propertyOwner, "Only owner can initialize");
        require(!initialized, "Contract already initialized");

        totalRealEstateValue = _initialPropertyPrice;
        saleEndTime = block.timestamp + _saleDuration;
        initialized = true; // make sure we only initialize once

        _mint(propertyOwner, totalRealEstateValue);
    }

    function InitializeICO(uint256 usdcAmount) public {
        require(block.timestamp < saleEndTime, "Sale period has ended");
        // transfer investor's usdc to this contract
        require(
            usdc.transferFrom(msg.sender, address(this), usdcAmount),
            "Transfer failed"
        );

        require(
            usdcAmount <= balanceOf(propertyOwner),
            "Not enough tokens available for sale"
        );

        // transfer ret to investor with 1 token = 1 usdc
        _transfer(propertyOwner, msg.sender, usdcAmount);

        // update sold tokens
        soldTokens += usdcAmount;
    }

    // transfer remaining into uniswap pair
    function finalizeICO() public {
        require(block.timestamp >= saleEndTime, "Sale has not ended yet");
        require(!saleEnded, "Sale already ended");
        require(
            msg.sender == propertyOwner,
            "Only property owner can end the sale"
        );

        uint256 remaining = balanceOf(address(this));
        if (remainingTokens > 0) {
            // 將剩餘代幣轉移到TradeController合約
            transfer(tradeControllerAddress, remainingTokens);

            // 從TradeController合約呼叫新增流動性的函數, 並設定每個token 面額為1u
            tradeController.createPairAndAddLiquidity(
                remainingTokens,
                remainingTokens
            );
        }
        saleEnded = true;
    }

    function getTotalRealEstateValue() public view returns (uint256) {
        return totalRealEstateValue;
    }
}
