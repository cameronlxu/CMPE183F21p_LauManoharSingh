pragma solidity ^0.5.1;
  
contract SmartContractGame {
    /*
        Timeline:
        ---------------------
        1. Register
        2. Make the bet
        3. Play the game
        4. Reveal the answer
        5. Payout to winner
    */

    // change bet unit if needed
    uint256 public constant MIN_BET = 1 wei; // minimum bet that a player can place
    uint256 public constant REVEAL_DEADLOCK = 10 minutes;
    uint256 public totalBet = 0;
    uint256 private firstRevealTime;
    bool public payoutPaid = false;
    bool public choiceReceived = false;
    bool public hashMatches = false;
    bytes32 public keyChoiceHash = 0x0;
    string public printWinner = "";
    string public printPlayerChoice = "";
    string public printHouseChoice = "";

    // Possible Options for Choices
    enum Choices {
        Left,
        Right,
        Empty
    }

    // Possible End Game Results
    enum Results {
        House,
        Player
    }

    // Address of the House and the Player
    address payable houseAddress = 0x10469edFf34f31fA1d54dC13907705b70f8DbD83;
    address payable public playerAddress;

    // The Choices is initially sent as encrypted
    bytes32 public encryptedChoice = 0x0;

    // Choices from enum
    Choices public playerChoice = Choices.Empty;
    Choices public houseChoice = Choices.Empty;

    /* Getter Functions for Testing */
    function getEncryptedChoice() public view returns (bytes32) {
        return encryptedChoice;
    }

    function getKeyChoiceHash() public view returns (bytes32) {
        return keyChoiceHash;
    }

    function getPlayerChoice() public view returns (string memory) {
        return printPlayerChoice;
    }

    function getHouseChoice() public view returns (string memory) {
        return printHouseChoice;
    }

    function getWinner() public view returns (string memory) {
        return printWinner;
    }

    /* Registration Phase */

    // checks if the players are registered in the game
    modifier checkRegistration() {
        require(msg.sender != playerAddress);
        _;
    }

    // Register the player
    function registerPlayer()
        public
        payable
        checkRegistration
        returns (uint256)
    {
        playerAddress = msg.sender;
        totalBet = msg.value;
        return 0;
    }

    /* Commit Phase */

    function increaseBet(uint256 amount) public payable {
        if (msg.sender == playerAddress) {
            totalBet += amount; //msg.value ?
        }
    }

    // This function takes in the hashed move outputted from the python script
    // If an encryptedChoice does not exist, assign the inputted hash value
    function gamePlay(bytes32 hashChoice)
        public
        returns (bool)
    {
        if (encryptedChoice == 0x0) {
            encryptedChoice = hashChoice;
            choiceReceived = true;
        } else {
            return false;
        }
        return true;
    }

    /* Reveal Phase */

    // Ensure an encryptedChoice was inputted into the contract
    modifier gameHasBeenPlayed() {
        require(encryptedChoice != 0x0);
        _;
    }

    // This function takes in the key provided from the python script
    function ShowAnswer(string memory key) public gameHasBeenPlayed returns (Choices) {
        // Encrypt the inputted key
        keyChoiceHash = sha256(abi.encodePacked(key));

        // Find what side was chosen (L or R)
        Choices LorR;
        if (discoverChoice(key) == 0) {
            LorR = Choices.Left;
            printPlayerChoice = "Left";
        } else {
            LorR = Choices.Right;
            printPlayerChoice = "Right";
        }

        // Verify that the hashed key matches the hash inputted in the gamePlay() function
        // This is what makes the game secure
        if (keyChoiceHash == encryptedChoice) {
            playerChoice = LorR;
            hashMatches = true;
        }

        // Determine the House choice via random
        houseChoice = pickRandomSide();

        // Find the winner
        findWinner();

        if (firstRevealTime == 0) {
            firstRevealTime = block.timestamp; // change unit
        }

        return LorR;
    }

    // Determine what move the player has made based on the key inputted in ShowAnswer()
    function discoverChoice(string memory str) private pure returns (uint256) {
        bytes1 firstCharacter = bytes(str)[0];
        if (firstCharacter == "L") {
            return 0;
        } else {
            return 1;
        }
    }

    // Using a random() function, have the house make a move
    // If random == 0, house chooses Left.
    // Else if random == 1, house chooses Right.
    function pickRandomSide() private returns (Choices) {
        uint findHouseChoice = random() % 2;
        if (findHouseChoice == 0) {
            printHouseChoice = "Left";
            return Choices.Left;
        } else {
            printHouseChoice = "Right";
            return Choices.Right;
        }
    }

    uint public randomNumber;

    // Random Function Referenced From: https://www.geeksforgeeks.org/random-number-generator-in-solidity-using-keccak256/ 
    function random() private returns (uint) {
        uint randNonce = 1;
        randomNumber = uint(keccak256(abi.encodePacked(now, msg.sender, randNonce))) % 2;
        return randomNumber;
    }

    /* Results Phase */

    // Ensure that both players have made a move
    modifier movesPlayed() {
        require(
            ((playerChoice == Choices.Left || playerChoice == Choices.Right) 
            && (houseChoice == Choices.Left || houseChoice == Choices.Right)) 
            || (firstRevealTime != 0 && block.timestamp > firstRevealTime + REVEAL_DEADLOCK)
        );
        _;
    }

    // Function that Determines the winner
    function findWinner() private movesPlayed returns (Results) {
        Results winner;
        if (playerChoice == houseChoice) {
            winner = Results.Player;
            printWinner = "Player";
        } else {
            winner = Results.House;
            printWinner = "House";
        }

        // Once determining the winner, release the payout
        payment(playerAddress, houseAddress, winner);
    }

    uint public toPayOut;

    // Pay the winner
    // Accepts both addresses and winner, determines the winner and pays out to that address
    function payment(address payable playerAddr, address payable houseAddr, Results theWinner) private {
        if (theWinner == Results.Player) {
            toPayOut = address(this).balance;
            houseAddr.transfer(toPayOut);
        } else {
            toPayOut = address(this).balance;
            playerAddr.transfer(toPayOut);
        }

        payoutPaid = true;
    } 
}