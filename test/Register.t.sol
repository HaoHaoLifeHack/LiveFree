// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/Register.sol";
import "../src/RealEstateToken.sol";

contract RegisterTest is Test {
    Register register;
    address uniswapV2FactoryAddress =
        address(0xc9f18c25Cfca2975d6eD18Fc63962EBd1083e978); // testnet // vm.envAddress("UNISWAPV2_FACTORY_ADDR")
    address propertyOwner;
    address investor;
    RealEstateToken ret;

    function setUp() public {
        register = new Register();
        propertyOwner = makeAddr("propertyOwner");
        investor = makeAddr("investor");
        uint256 totalSupply = 1000000 * 1e6;
        uint256 saleDuration = 1 weeks; //7 * 24 * 60 * 60 秒，即 604800 秒
        vm.startPrank(propertyOwner);
        register.registerProperty(totalSupply, saleDuration);
        vm.stopPrank();
        (address owner, address tokenAddress) = register.properties(0);
        require(tokenAddress != address(0));
        ret = RealEstateToken(tokenAddress);
        assertEq(owner, propertyOwner);
        require(tokenAddress != address(0));
        assertEq(ret.getInitialPropertyPrice(), totalSupply);
        assertGt(ret.saleEndTime(), block.timestamp);
    }

    // function testRegisterProperty() public {
    //     assertEq(owner, propertyOwner);
    //     require(tokenAddress != address(0));
    //     assertEq(ret.getInitialPropertyPrice(), totalSupply);
    //     assertGt(ret.saleEndTime(), block.timestamp);
    // }

    function testInitialCoinOffering() public {
        vm.startPrank(investor);
        ret.InitialCoinOffering(1000 * 1e6); //bug
        assertEq(ret.balanceOf(investor), 1000 * 1e6);
        vm.stopPrank();
    }

    function testInitialCoinOfferingEnd() public {
        vm.startPrank(investor);
        //TODO: test when sale end
    }
}
