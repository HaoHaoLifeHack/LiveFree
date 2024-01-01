// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/Register.sol";
import "../src/RealEstateToken.sol";
import "../src/TradeController.sol";
import "v2-core/interfaces/IUniswapV2Pair.sol";

contract TradeControllerTest is Test {
    event PairCreated(
        address indexed token1,
        address indexed token2,
        address pair
    );
    // RET
    Register register;
    TradeController tradeController;
    uint256 saleDuration = 1 weeks;

    // Uniswap
    IUniswapV2Factory factory =
        IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
    // Mainnet: 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f
    // Sepolia: 0xc9f18c25Cfca2975d6eD18Fc63962EBd1083e978
    // vm.envAddress("UNISWAPV2_FACTORY_ADDR")
    IUniswapV2Router02 router =
        IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    // Mainnet: 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
    // Sepolia: 0xC532a74256D3Db42D0Bf7a0400fEFDbad7694008
    // vm.envAddress("UNISWAPV2_FACTORY_ADDR")

    address pair;
    // Roles
    address propertyOwner;
    address investor;
    address liquidityProvider;

    // Tokens
    RealEstateToken ret;
    ERC20 usdc;

    function setUp() public {
        //fork mainnet at block 17465000
        string memory rpc = vm.envString("MAINNET_RPC_URL");
        // MAINNET_RPC_URL
        // SEPOLIA_RPC_URL
        vm.createSelectFork(rpc, 17465000);
        // Mainnet: 17465000
        // Sepolia: 2515638

        //roles
        register = new Register();
        propertyOwner = makeAddr("propertyOwner");
        investor = makeAddr("investor");
        liquidityProvider = makeAddr("LiquidityProvider");
        //tokens
        usdc = ERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
        // Mainnet: 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48
        // Sepolia: 0xf08A50178dfcDe18524640EA6618a1f965821715
        uint256 realWorldValue = 1000000 * 1e6;
        vm.startPrank(propertyOwner);
        register.registerProperty(realWorldValue, saleDuration);
        vm.stopPrank();
        (, address tokenAddress) = register.properties(0);
        ret = RealEstateToken(tokenAddress);

        //(address _factory, address _router, address _ret, address _usdc)
        tradeController = new TradeController(
            address(factory),
            address(router),
            address(ret),
            address(usdc)
        );

        // initial balance
        deal(address(usdc), propertyOwner, 100000 * 1e6);
        deal(address(usdc), investor, 100000 * 1e6);
        deal(address(usdc), liquidityProvider, 1000000 * 1e6);
        deal(address(ret), liquidityProvider, 1000000 * 1e6);

        // label address
        vm.label(address(register), "register");
        vm.label(address(ret), "ret");
        vm.label(address(usdc), "usdc");
        vm.label(address(router), "router");
        vm.label(address(factory), "factory");
        vm.label(address(tradeController), "tradeController");
    }

    function testCreatePairWithUSDC() public {
        // // 模擬期望的事件
        // vm.expectEmit(true, true, false, true);
        // emit PairCreated(address(ret), address(usdc), pair); // 使用模擬的地址

        // 呼叫 createPairWithUSDC 函數
        address pair = tradeController.createPairWithUSDC();
        assertEq(
            pair,
            IUniswapV2Factory(factory).getPair(address(ret), address(usdc))
        );

        // 驗證事件是否如預期觸發
        // 進一步的驗證可以加在這裡
    }

    function testAddLiquidity() public {
        createPair();
        console2.log("pair addr: ", pair);
        vm.label(address(pair), "pair");
        uint retAmount = 100e6; // 100 RET
        uint usdcAmount = 100e6; // 100 USDC

        // 呼叫 addLiquidity 函數
        vm.startPrank(liquidityProvider);
        console2.log(
            "liquidityProvider's ret: ",
            ret.balanceOf(liquidityProvider)
        );
        console2.log(
            "liquidityProvider's usdc: ",
            usdc.balanceOf(liquidityProvider)
        );
        ret.approve(address(tradeController), retAmount);
        usdc.approve(address(tradeController), usdcAmount);

        tradeController.addLiquidity(retAmount, usdcAmount);
        // 驗證代幣是否被轉移和批准
        // 進一步的驗證可以加在這裡
        console2.log(IUniswapV2Pair(pair).balanceOf(liquidityProvider));
        (uint retReserve, uint usdcReserve, ) = IUniswapV2Pair(pair)
            .getReserves();
        assertEq(retReserve, retAmount);
        assertEq(usdcReserve, usdcAmount);
        vm.stopPrank();
    }

    //bug
    function testRemoveLiquidity() public {
        addLiquidity();
        uint liquidity = 50e6; // 預計移除的流動性
        vm.startPrank(liquidityProvider);
        // 呼叫 removeLiquidity 函數
        tradeController.removeLiquidity(liquidity);
        // record liquidity before remove
        (uint retReserveOld, uint usdcReserveOld, ) = IUniswapV2Pair(pair)
            .getReserves();
        // 驗證流動性是否被移除
        assertEq(IUniswapV2Pair(pair).balanceOf(liquidityProvider), liquidity);
        (uint retReserve, uint usdcReserve, ) = IUniswapV2Pair(pair)
            .getReserves();
        assertEq(retReserve, retReserveOld - liquidity);
        assertEq(usdcReserve, usdcReserveOld - liquidity);
        vm.stopPrank();
    }

    function addLiquidity() private {
        createPair();
        vm.startPrank(liquidityProvider);
        uint retAmount = 100e6; // 100 RET
        uint usdcAmount = 100e6; // 100 USDC
        ret.approve(address(tradeController), retAmount);
        usdc.approve(address(tradeController), usdcAmount);
        tradeController.addLiquidity(retAmount, usdcAmount);
        vm.stopPrank();
    }

    function createPair() private {
        pair = tradeController.createPairWithUSDC();
    }

    function testSwapUSDCForTokens() public {
        uint usdcAmount = 50e6; // buy 50 RET
        // 呼叫 swapUSDCForTokens 函數
        vm.startPrank(investor);
        // ret.approve(address(tradeController), ret.balanceOf(investor));
        usdc.approve(address(tradeController), usdc.balanceOf(investor));
        tradeController.swapUSDCForTokens(usdcAmount);
        console2.log(ret.balanceOf(investor));
        // 驗證 USDC 兌換
        // 進一步的驗證可以加在這裡
        vm.stopPrank();
    }

    function testSwapTokensForUSDC() public {
        uint retAmount = 80e6; // buy 80 usdc

        // 呼叫 swapTokensForUSDC 函數
        vm.startPrank(investor);
        ret.approve(address(tradeController), ret.balanceOf(investor));
        // usdc.approve(address(tradeController), usdc.balanceOf(investor));
        tradeController.swapTokensForUSDC(retAmount);

        // 驗證RET兌換
        // 進一步的驗證可以加在這裡
        vm.stopPrank();
    }
}
