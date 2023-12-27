// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "v2-core/interfaces/IUniswapV2Factory.sol";

contract RealEstateToken is ERC20 {
    address public propertyOwner;
    uint256 private _totalSupply;
    uint256 private totalTokenSupply;
    uint256 public saleEndTime;
    uint256 public tokenPrice = 1e6; // Token initial price，1 token = 1 u
    IERC20 public usdc = IERC20(0x94a9D9AC8a22534E3FaCa9F4e7F2E2cf85d5E4C8);
    IUniswapV2Factory public uniswapV2Factory;

    constructor(
        address _owner,
        uint256 _initialPropertyPrice,
        uint256 _saleDuration
    ) ERC20("RealEstateToken", "RET") {
        propertyOwner = _owner;
        totalTokenSupply = _initialPropertyPrice;
        saleEndTime = block.timestamp + _saleDuration;
        //uniswapV2Factory.createPair(address(this), address(usdc));
    }

    function InitialCoinOffering(uint256 amount) public {
        require(block.timestamp < saleEndTime, "Sale period has ended");
        require(
            usdc.transferFrom(msg.sender, address(this), amount),
            "Transfer failed"
        );
        _mint(msg.sender, amount);
    }

    // function _mint(address account, uint256 amount) internal virtual {
    //     require(amount > 0, "Amount must be greater than 0");
    //     require(account != address(0), "Account must not be 0");
    //     _totalSupply += amount;
    //     emit Transfer(address(0), account, amount);
    // }

    function mintRemainingToOwner() public {
        require(block.timestamp >= saleEndTime, "Sale period not ended yet");
        uint256 remaining = totalSupply() - balanceOf(address(this));
        if (remaining > 0) {
            _mint(propertyOwner, remaining);
        }
    }

    // function totalSupply() public view override returns (uint256) {
    //     return _totalSupply;
    // }

    function getInitialPropertyPrice() public view returns (uint256) {
        return totalTokenSupply;
    }

    function setSaleDurationEnd() public {
        //for test
        saleEndTime = 1;
    }
}
