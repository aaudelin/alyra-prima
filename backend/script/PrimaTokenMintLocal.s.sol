// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {PrimaToken} from "../src/PrimaToken.sol";

/**
 * @title PrimaTokenMintLocalScript
 * @notice Script for minting the PrimaToken contract
 * @author @aaudelin
 */
contract PrimaTokenMintLocalScript is Script {
    PrimaToken public primaToken;

    function run(address primaTokenAddress) public {
        vm.startBroadcast(msg.sender);

        address[3] memory tos = [
            0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266,
            0x70997970C51812dc3A010C7d01b50e0d17dc79C8,
            0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC
        ];
        uint256 amount = 10000 ether;

        primaToken = PrimaToken(primaTokenAddress);

        for (uint256 i = 0; i < tos.length; i++) {
            primaToken.mint(tos[i], amount);
        }

        vm.stopBroadcast();
    }

    function runSepolia(address primaTokenAddress) public {
        vm.startBroadcast(msg.sender);

        address[3] memory tos = [
            0x88cf3F31fe3c067185fFC85170bE11abb101dE87,
            0x29F2D60B0e77f76f7208FA910C51EFef98480501,
            0xe30800Fe0775E47CccC62E04E25036E1647a4607
        ];
        uint256 amount = 10000 ether;

        primaToken = PrimaToken(primaTokenAddress);

        for (uint256 i = 0; i < tos.length; i++) {
            primaToken.mint(tos[i], amount);
        }

        vm.stopBroadcast();
    }
}
