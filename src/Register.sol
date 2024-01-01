// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./RealEstateToken.sol";

contract Register {
    struct Property {
        address owner;
        address tokenAddress;
    }
    mapping(uint256 => Property) public properties;
    uint256 public nextPropertyId;

    event PropertyRegistered(
        uint256 indexed propertyId,
        address indexed owner,
        address tokenAddress
    );

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
