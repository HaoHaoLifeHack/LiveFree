// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/Register.sol";
import "../src/RealEstateToken.sol";

contract RegisterTest is Test {
    event PropertyRegistered(
        uint256 indexed propertyId,
        address indexed owner,
        address tokenAddress
    );
    Register register;
    address propertyOwner;
    RealEstateToken ret;
    uint256 saleDuration = 1 weeks; //7 * 24 * 60 * 60 秒，即 604800 秒
    uint256 realWorldValue = 1000000 * 1e6; // 1 usd = 1 usdc

    function setUp() public {
        //roles
        register = new Register();
        propertyOwner = makeAddr("propertyOwner");
    }

    function testRegisterProperty() public {
        vm.startPrank(propertyOwner);

        // Call function
        register.registerProperty(realWorldValue, saleDuration);
        vm.stopPrank();
        (address owner, address tokenAddress) = register.properties(0);
        ret = RealEstateToken(tokenAddress);

        require(tokenAddress != address(0));
        assertEq(owner, propertyOwner);
        require(tokenAddress != address(0));
        assertEq(ret.getInitialPropertyPrice(), realWorldValue);
        assertGt(ret.saleEndTime(), saleDuration);

        // 設置預期的事件, // 1, 2, 3 是有建立的indexed的索引參數的期望值，當有設置indexed方便進行事件過濾; 4. 事件的data即那些沒有標記為 indexed 的參數
        // vm.expectEmit(true, true, false, true);
        // emit PropertyRegistered(0, propertyOwner, address(ret)); // 使用具體的期望值
    }
}
