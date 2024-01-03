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

    function createPairWithUSDC(
        uint256 tokenAmount,
        uint256 usdcAmount
    ) public returns (address pair) {
        pair = uniswapV2Factory.createPair(ret, usdc);
        emit PairCreated(ret, usdc, pair);
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
        // 確保合約有足夠的代幣權限
        ret.approve(address(uniswapRouter), tokenAmount);
        usdc.approve(address(uniswapRouter), usdcAmount);

        uniswapFactory.createPair(address(ret), address(usdc));
        emit PairCreated(ret, usdc, pair);

        // 添加流動性
        uniswapRouter.addLiquidity(
            address(ret),
            address(usdc),
            tokenAmount,
            usdcAmount,
            0, // 最小代幣數量
            0, // 最小USDC數量
            address(this),
            block.timestamp
        );
    }

    // function removeLiquidity(uint liquidity) public {
    //     IERC20 liquidityToken = IERC20(
    //         UniswapV2Library.pairFor(address(uniswapV2Factory), ret, usdc)
    //     );
    //     liquidityToken.transferFrom(msg.sender, address(this), liquidity);
    //     liquidityToken.approve(address(uniswapV2Router), liquidity);

    //     uniswapV2Router.removeLiquidity(
    //         ret,
    //         usdc,
    //         liquidity,
    //         0, // 設定最小接收量為0
    //         0, // 設定最小接收量為0
    //         msg.sender,
    //         block.timestamp
    //     );
    // }

    // function swapUSDCForTokens(uint usdcAmount) public {
    //     IERC20(usdc).transferFrom(msg.sender, address(this), usdcAmount);
    //     IERC20(usdc).approve(address(uniswapV2Router), usdcAmount);

    //     address[] memory path = new address[](2);
    //     path[0] = usdc; // 來源token
    //     path[1] = ret; // 目標token

    //     uniswapV2Router.swapExactTokensForTokens(
    //         usdcAmount,
    //         0, // 設定最小接收量為0表示可接受任何數量的RET
    //         path,
    //         msg.sender,
    //         block.timestamp
    //     );
    // }

    // function swapTokensForUSDC(uint tokenAmount) public {
    //     IERC20(ret).transferFrom(msg.sender, address(this), tokenAmount);
    //     IERC20(ret).approve(address(uniswapV2Router), tokenAmount);

    //     address[] memory path = new address[](2);
    //     path[0] = ret; // 來源token
    //     path[1] = usdc; // 目標token

    //     uniswapV2Router.swapExactTokensForTokens(
    //         tokenAmount,
    //         0, // 設定最小接收量為0表示可接受任何數量的USDC
    //         path,
    //         msg.sender,
    //         block.timestamp
    //     );
    // }
}
