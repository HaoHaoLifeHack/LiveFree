// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "v2-core/interfaces/IUniswapV2Factory.sol";

contract RealEstateToken is ERC20 {
    address public propertyOwner;
    uint256 private totalTokenSupply;
    uint256 public soldTokens; // track sold tokens
    uint256 public saleEndTime;
    bool public saleEnded;

    uint256 public tokenPrice = 1e6; // Token initial price，1 token = 1 u
    IERC20 public usdc = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    IUniswapV2Factory public uniswapV2Factory;

    constructor(
        address _owner,
        uint256 _initialPropertyPrice,
        uint256 _saleDuration
    ) ERC20("RealEstateToken", "RET") {
        propertyOwner = _owner;
        totalTokenSupply = _initialPropertyPrice;
        saleEndTime = block.timestamp + _saleDuration;
        saleEnded = false;
    }

    function InitialCoinOffering(uint256 amount) public {
        require(block.timestamp < saleEndTime, "Sale period has ended");
        require(
            usdc.transferFrom(msg.sender, address(this), amount),
            "Transfer failed"
        );
        _mint(msg.sender, amount);
        soldTokens += amount; // update sold tokens
    }

    function endICO() public {
        require(block.timestamp >= saleEndTime, "Sale has not ended yet");
        require(!saleEnded, "Sale already ended");
        require(
            msg.sender == propertyOwner,
            "Only property owner can end the sale"
        );

        uint256 remaining = totalSupply() - balanceOf(address(this));
        if (remaining > 0) {
            _mint(propertyOwner, remaining);
        }
        saleEnded = true;
    }

    function getInitialPropertyPrice() public view returns (uint256) {
        return totalTokenSupply;
    }
}
