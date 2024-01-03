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
        string memory _ipfsHash,
        uint256 _initialPropertyPrice,
        uint256 _saleDuration
    ) public returns (address tokenAddress) {
        bytes32 salt = keccak256(abi.encodePacked(_ipfsHash));
        bytes memory bytecode = type(RealEstateToken).creationCode;
        require(isContractDeployed(_ipfsHash), "Property already registered");

        assembly {
            tokenAddress := create2(
                0,
                add(bytecode, 0x20),
                mload(bytecode),
                salt
            )
        }

        require(tokenAddress != address(0), "Failed to deploy token");

        emit PropertyRegistered(nextPropertyId, msg.sender, tokenAddress);
        nextPropertyId++;
    }

    function isContractDeployed(
        string memory _ipfsHash
    ) public view returns (bool) {
        address expectedAddress = calculateExpectedAddress(_ipfsHash);
        uint256 size;
        assembly {
            size := extcodesize(expectedAddress)
        }
        return size > 0;
    }

    function calculateExpectedAddress(
        string memory _ipfsHash
    ) public view returns (address) {
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

        return address(uint160(uint256(hash)));
    }

    // function registerPropertyOld(
    //     uint256 _initialPropertyPrice,
    //     uint256 _saleDuration,
    //     string memory _ipfsHash
    // ) public {
    //     // 將IPFS的hash(unique)轉換成bytes32作為salt
    //     bytes32 salt = keccak256(abi.encodePacked(_ipfsHash));

    //     RealEstateToken token = new RealEstateToken(
    //         msg.sender,
    //         _initialPropertyPrice,
    //         _saleDuration
    //     );
    //     properties[nextPropertyId] = Property({
    //         owner: msg.sender,
    //         tokenAddress: address(token)
    //     });

    //     emit PropertyRegistered(nextPropertyId, msg.sender, address(token));
    //     nextPropertyId++;
    // }
}
