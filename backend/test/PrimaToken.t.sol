// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "forge-std/Test.sol";
import {PrimaToken} from "../src/PrimaToken.sol";
import {PrimaTokenScript} from "../script/PrimaToken.s.sol";
import {PrimaTokenMintLocalScript} from "../script/PrimaTokenMintLocal.s.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract PrimaTokenTest is Test {
    PrimaToken primaToken;

    function setUp() public {
        primaToken = new PrimaToken();
    }

    function test_Deployment() public view {
        assertEq(primaToken.name(), "Prima");
        assertEq(primaToken.symbol(), "PGT");
        assertEq(primaToken.decimals(), 18);
    }

    function test_Deployment_Script() public {
        PrimaTokenScript primaTokenScript = new PrimaTokenScript();
        primaTokenScript.run();
        PrimaToken primaTokenScripted = primaTokenScript.primaToken();

        assertEq(primaTokenScripted.name(), "Prima");
        assertEq(primaTokenScripted.symbol(), "PGT");
        assertEq(primaTokenScripted.decimals(), 18);
    }

    function test_Mint() public {
        vm.startPrank(address(this));
        primaToken.mint(address(this), 100);
        assertEq(primaToken.balanceOf(address(this)), 100);
        vm.stopPrank();
    }
}

contract PrimaTokenMintScriptTest is Test {
    PrimaTokenMintLocalScript primaTokenMintLocalScript;
    PrimaToken primaToken;

    function setUp() public {
        primaToken = new PrimaToken();
        primaTokenMintLocalScript = new PrimaTokenMintLocalScript();
    }

    function test_Mint_Script_Local() public {
        primaTokenMintLocalScript.run(address(primaToken));
        assertEq(primaToken.balanceOf(address(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266)), 10000 ether);
        assertEq(primaToken.balanceOf(address(0x70997970C51812dc3A010C7d01b50e0d17dc79C8)), 10000 ether);
        assertEq(primaToken.balanceOf(address(0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC)), 10000 ether);
    }

    function test_Mint_Script_Sepolia() public {
        primaTokenMintLocalScript.runSepolia(address(primaToken));
        assertEq(primaToken.balanceOf(address(0x88cf3F31fe3c067185fFC85170bE11abb101dE87)), 10000 ether);
        assertEq(primaToken.balanceOf(address(0x29F2D60B0e77f76f7208FA910C51EFef98480501)), 10000 ether);
        assertEq(primaToken.balanceOf(address(0xe30800Fe0775E47CccC62E04E25036E1647a4607)), 10000 ether);
    }
}