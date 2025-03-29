// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "forge-std/Test.sol";
import {PrimaToken} from "../src/PrimaToken.sol";
import {PrimaTokenScript} from "../script/PrimaToken.s.sol";

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
