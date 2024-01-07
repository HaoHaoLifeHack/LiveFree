// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/console.sol";
import "./RealEstateToken.sol";

contract Register {
    struct Property {
        address owner;
        address tokenAddress;
    }
    mapping(uint256 => Property) public properties;
    uint256 public nextPropertyId = 0;

    event PropertyRegistered(
        uint256 indexed propertyId,
        address indexed owner,
        address tokenAddress
    );

    function registerProperty(
        string memory _ipfsHash,
        uint256 _initialPropertyPrice,
        uint256 _saleDuration,
        address _usdc
    ) public returns (address tokenAddress) {
        bytes memory bytecode = type(RealEstateToken).creationCode;
        require(!isContractDeployed(_ipfsHash), "Property already registered");
        console.log("_ipfsHash: ", _ipfsHash);
        bytes32 salt = keccak256(abi.encodePacked(_ipfsHash));
        console.logBytes32(salt);

        assembly {
            tokenAddress := create2(
                0,
                add(bytecode, 0x20),
                mload(bytecode),
                salt
            )
        }
        console.log("tokenAddress: ", tokenAddress);
        require(tokenAddress != address(0), "Failed to deploy token");
        properties[nextPropertyId] = Property(msg.sender, tokenAddress);

        emit PropertyRegistered(nextPropertyId, msg.sender, tokenAddress);
        nextPropertyId++;

        RealEstateToken(tokenAddress).initialize(
            msg.sender,
            _initialPropertyPrice,
            _saleDuration,
            _usdc
        );
    }

    function isContractDeployed(
        string memory _ipfsHash
    ) private view returns (bool) {
        address expectedAddress = calculateExpectedAddress(_ipfsHash);
        uint256 size;
        assembly {
            size := extcodesize(expectedAddress)
        }
        console.logUint(size);
        return size > 0;
    }

    function calculateExpectedAddress(
        string memory _ipfsHash
    ) private view returns (address) {
        bytes32 salt = keccak256(abi.encodePacked(_ipfsHash));
        bytes memory bytecode = abi.encodePacked(
            type(RealEstateToken).creationCode
        );

        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0xff),
                address(this),
                salt,
                keccak256(bytecode)
            )
        );

        //1. hash被轉換為uint256型別
        //2. uint256被轉換為uint160型別，因為以太坊地址是160位的
        //3. uint160轉換為address型別，得到預期的合約地址。
        return address(uint160(uint256(hash)));
    }
}
