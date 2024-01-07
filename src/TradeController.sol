// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "v2-periphery/interfaces/IUniswapV2Router02.sol";
import "v2-periphery/libraries/UniswapV2Library.sol";
import "v2-core/interfaces/IUniswapV2Factory.sol";

contract TradeController {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair
    );

    IUniswapV2Factory public uniswapV2Factory;
    IUniswapV2Router02 uniswapV2Router;

    address private ret;
    address private usdc;

    constructor(
        address _factory,
        address _router,
        address _ret,
        address _usdc
    ) {
        uniswapV2Factory = IUniswapV2Factory(_factory);
        uniswapV2Router = IUniswapV2Router02(_router);
        ret = _ret;
        usdc = _usdc;
    }

    function createPairWithUSDC() public returns (address pair) {
        pair = uniswapV2Factory.createPair(ret, usdc);
        emit PairCreated(usdc, ret, pair);
    }

    function addLiquidity(uint tokenAmount, uint usdcAmount) public {
        IERC20(ret).transferFrom(msg.sender, address(this), tokenAmount);
        IERC20(usdc).transferFrom(msg.sender, address(this), usdcAmount);

        IERC20(ret).approve(address(uniswapV2Router), tokenAmount);
        IERC20(usdc).approve(address(uniswapV2Router), usdcAmount);

        uniswapV2Router.addLiquidity(
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

    function createPairAndAddLiquidity(
        uint256 tokenAmount,
        uint256 usdcAmount
    ) external {
        IERC20(ret).transferFrom(msg.sender, address(this), tokenAmount);
        IERC20(usdc).transferFrom(msg.sender, address(this), usdcAmount);
        // 確保合約有足夠的代幣權限
        IERC20(ret).approve(address(uniswapV2Router), tokenAmount);
        IERC20(usdc).approve(address(uniswapV2Router), usdcAmount);

        address pair = uniswapV2Factory.createPair(address(ret), address(usdc));
        emit PairCreated(usdc, ret, pair);

        // 添加流動性
        uniswapV2Router.addLiquidity(
            ret,
            usdc,
            tokenAmount,
            usdcAmount,
            0, // 最小代幣數量
            0, // 最小USDC數量
            msg.sender,
            block.timestamp
        );
    }
}
