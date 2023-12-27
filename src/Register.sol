// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./RealEstateToken.sol";

//import "v2-core/interfaces/IUniswapV2Factory.sol";

contract Register {
    struct Property {
        address owner;
        address tokenAddress;
    }
    IUniswapV2Factory public uniswapV2Factory;
    mapping(uint256 => Property) public properties;
    uint256 public nextPropertyId;

    event PropertyRegistered(
        uint256 indexed propertyId,
        address indexed owner,
        address tokenAddress
    );

    // constructor(address _uniswapV2Factory) {
    //     uniswapV2Factory = IUniswapV2Factory(_uniswapV2Factory);
    // }

    function registerProperty(
        uint256 _initialPropertyPrice,
        uint256 _saleDuration
    ) public {
        RealEstateToken token = new RealEstateToken(
            msg.sender,
            _initialPropertyPrice,
            _saleDuration
        );
        properties[nextPropertyId] = Property({
            owner: msg.sender,
            tokenAddress: address(token)
        });

        emit PropertyRegistered(nextPropertyId, msg.sender, address(token));
        nextPropertyId++;
    }
}
