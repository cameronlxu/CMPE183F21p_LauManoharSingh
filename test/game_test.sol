// SPDX-License-Identifier: GPL-3.0
    
pragma solidity >=0.4.22 <0.9.0;

import "remix_tests.sol"; 
import "remix_accounts.sol";
import "../src/game.sol";

contract testSuite is SmartContractGame {

    // Addresses for both players
    address house = 0x10469edFf34f31fA1d54dC13907705b70f8DbD83;
    address playerAddress;

    // Assign playerAddress an address
    function beforeAll() public {
        playerAddress = TestsAccounts.getAccount(0);
    }

    // Ensure after registering that the playerAddress is equal to the msg.sender
    // There is no initial bet, so ensure it is 0
    function checkTheRegistration() payable public {
        registerPlayer();
        Assert.ok(msg.sender == playerAddress, 'playerAddress should hold player address');
        Assert.equal(msg.value, 0, "initial bet starts at 0");
    }

    // Ensure the encrypted choice is assigned to variable "EncryptedChoice"
    function checkGamePlay() public {
        gamePlay(0xe45907dc12b6780a40e2d33c72a25181b8738269245e3c6c10983b7cf6e12319);
        Assert.equal(getEncryptedChoice(), 0xe45907dc12b6780a40e2d33c72a25181b8738269245e3c6c10983b7cf6e12319, "received encrypted choice");
    }

    // Ensure that the inputted key hash matches variable "EncryptedChoice"
    function checkShowAnswer() public {
        ShowAnswer("L-password");
        Assert.equal(getEncryptedChoice(), getKeyChoiceHash(), "check hash matches");

        // Ensure that moves made by Player and House are either Left or Right
        Assert.ok(
            keccak256(abi.encodePacked(getPlayerChoice())) == keccak256(abi.encodePacked("Left")), 
            "Ensure player move is Left or Right"
        );
        Assert.ok(
            keccak256(abi.encodePacked(getHouseChoice())) == keccak256(abi.encodePacked("Left"))
            || keccak256(abi.encodePacked(getHouseChoice())) == keccak256(abi.encodePacked("Right")), 
            "Ensure house move is Left or Right"
        );

        // Ensure the winner is either the Player or the House
        Assert.ok(
            keccak256(abi.encodePacked(getWinner())) == keccak256(abi.encodePacked("Player"))
            || keccak256(abi.encodePacked(getWinner())) == keccak256(abi.encodePacked("House")),
            "Ensure winner is either Player or House" 
        );
    }
}
