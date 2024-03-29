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
    ERC20 usdc;
    uint256 saleDuration = 1 weeks; //7 * 24 * 60 * 60 秒，即 604800 秒
    uint256 realWorldValue = 1000000 * 1e6; // 1 usd = 1 usdc
    string ipfsHash = "QmT7NFqXfvpZ6Q6wW6Lf2P4RgTNQgz3e6rAFSVz1Tvax6w";

    function setUp() public {
        //roles
        register = new Register();
        propertyOwner = makeAddr("propertyOwner");
        usdc = ERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    }

    function testRegisterProperty() public {
        vm.startPrank(propertyOwner);

        // Call function
        register.registerProperty(
            ipfsHash,
            realWorldValue,
            saleDuration,
            address(usdc)
        );
        vm.stopPrank();
        (address owner, address tokenAddress) = register.properties(0);
        ret = RealEstateToken(tokenAddress);

        require(tokenAddress != address(0));
        assertEq(owner, propertyOwner);
        require(tokenAddress != address(0));
        assertEq(ret.getTotalRealEstateValue(), realWorldValue);
        assertGt(ret.saleEndTime(), saleDuration);

        // 設置預期的事件, // 1, 2, 3 是有建立的indexed的索引參數的期望值，當有設置indexed方便進行事件過濾; 4. 事件的data即那些沒有標記為 indexed 的參數
        // vm.expectEmit(true, true, false, true);
        // emit PropertyRegistered(0, propertyOwner, address(ret)); // 使用具體的期望值
    }

    function testDuplicateRegisterProperty() public {
        testRegisterProperty();

        vm.startPrank(propertyOwner);

        vm.expectRevert("Property already registered");
        // Call function
        register.registerProperty(
            ipfsHash,
            realWorldValue,
            saleDuration,
            address(usdc)
        );
        vm.stopPrank();
    }
}
