// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import "v2-periphery/interfaces/IUniswapV2Router02.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TradeController {
    IUniswapV2Router02 uniswapRouter;
    address private ret;
    address private usdc;

    constructor(address _router, address _ret, address _usdc) {
        uniswapRouter = IUniswapV2Router02(_router);
        ret = _ret;
        usdc = _usdc;
    }

    function addLiquidity(uint tokenAmount, uint usdcAmount) public {
        IERC20(ret).transferFrom(msg.sender, address(this), tokenAmount);
        IERC20(usdc).transferFrom(msg.sender, address(this), usdcAmount);

        IERC20(ret).approve(address(uniswapRouter), tokenAmount);
        IERC20(usdc).approve(address(uniswapRouter), usdcAmount);

        uniswapRouter.addLiquidity(
            ret,
            usdc,
            tokenAmount,
            usdcAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            msg.sender,
            block.timestamp
        );
    }
}
