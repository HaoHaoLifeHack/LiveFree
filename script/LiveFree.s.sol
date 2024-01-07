// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console2} from "forge-std/Script.sol";
import "../src/Register.sol";
import "../src/RealEstateToken.sol";
import "../src/TradeController.sol";
import "../src/DividendDistribution.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "v2-periphery/interfaces/IUniswapV2Router02.sol";
import "v2-periphery/libraries/UniswapV2Library.sol";
import "v2-core/interfaces/IUniswapV2Factory.sol";

contract LiveFreeScript is Script {
    //forge script script/LiveFreeScript.s.sol --rpc-url https://eth-sepolia.g.alchemy.com/v2/skSSwajFv3eJH3DG25u0Q6OSrzMGl9sc
    string ETHEREUM_RPC_URL = vm.envString("SEPOLIA_RPC_URL");
    uint PRIVATE_KEY = vm.envUint("PRIVATE_KEY");

    function run() public {
        uint256 initialPropertyPrice = 1000000e6;
        uint256 saleDuration = 1 weeks;
        string
            memory ipfsHash = "QmT7NFqXfvpZ6Q6wW6Lf2P4RgTNQgz3e6rAFSVz1Tvax6w";
        address usdc = vm.envAddress("USDC_SEPOLIA_ADDR");

        vm.startBroadcast(PRIVATE_KEY);
        Register register = new Register();
        address ret = register.registerProperty(
            ipfsHash,
            initialPropertyPrice,
            saleDuration,
            usdc
        );

        address factory = vm.envAddress("UNISWAPV2_FACTORY_SEPOLIA_ADDR");
        address router = vm.envAddress("UNISWAPV2_ROUTER_SEPOLIA_ADDR");

        TradeController tradeController = new TradeController(
            factory,
            router,
            ret,
            usdc
        );

        DividendDistribution dividendDistribution = new DividendDistribution();

        vm.stopBroadcast();
    }
}
