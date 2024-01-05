// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/Register.sol";
import "../src/RealEstateToken.sol";

contract RealEstateTokenTest is Test {
    Register register;
    address uniswapV2FactoryAddress =
        address(0xc9f18c25Cfca2975d6eD18Fc63962EBd1083e978); // testnet // vm.envAddress("UNISWAPV2_FACTORY_ADDR")
    address propertyOwner;
    address investor;
    RealEstateToken ret;
    ERC20 usdc;
    uint256 saleDuration = 1 weeks; //7 * 24 * 60 * 60 秒，即 604800 秒
    string ipfsHash = "QmT7NFqXfvpZ6Q6wW6Lf2P4RgTNQgz3e6rAFSVz1Tvax6w";

    function setUp() public {
        //fork mainnet at block 17465000
        string memory rpc = vm.envString("MAINNET_RPC_URL");
        vm.createSelectFork(rpc, 17465000);

        //roles
        register = new Register();
        propertyOwner = makeAddr("propertyOwner");
        investor = makeAddr("investor");

        //tokens
        usdc = ERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);

        uint256 realWorldValue = 1000000 * 1e6;

        vm.startPrank(propertyOwner);
        register.registerProperty(ipfsHash, realWorldValue, saleDuration);
        vm.stopPrank();
        (address owner, address tokenAddress) = register.properties(0);
        ret = RealEstateToken(tokenAddress);
        require(tokenAddress != address(0));

        assertEq(owner, propertyOwner);
        require(tokenAddress != address(0));
        assertEq(ret.getTotalRealEstateValue(), realWorldValue);
        assertGt(ret.saleEndTime(), block.timestamp);
        deal(address(usdc), investor, 100000 * 1e6);
    }

    function testInitializeICO() public {
        vm.startPrank(investor);
        usdc.approve(address(ret), usdc.balanceOf(investor));
        usdc.balanceOf(investor);
        ret.balanceOf(investor);
        ret.InitializeICO(1000 * 1e6);
        assertEq(ret.balanceOf(investor), 1000 * 1e6);
        vm.stopPrank();
    }

    function testMintToOwnerAfterFinalizeICO() public {
        // simulate time fly to the end of ICO
        vm.warp(block.timestamp + saleDuration + 1);

        // property owner ends the sale
        vm.prank(propertyOwner);
        ret.finalizeICO();

        // property owner should receive all remaining tokens
        uint256 remainingTokens = ret.balanceOf(propertyOwner);
        uint256 expectedRemaining = ret.totalSupply() - ret.soldTokens(); // 追蹤已售出的代幣數量
        assertEq(
            remainingTokens,
            expectedRemaining,
            "Property owner should receive all remaining tokens"
        );
    }
}
