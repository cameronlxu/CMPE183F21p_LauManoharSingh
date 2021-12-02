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

    uint256 public constant MIN_BET = 1 wei; // minimum bet that a player can place
    uint256 public constant REVEAL_DEADLOCK = 10 minutes;
    uint256 public totalBet = 0;
    uint256 private firstRevealTime;
    bool payoutPaid = false;

    enum Choices {
        Left,
        Right,
        Empty
    }

    enum Results {
        House,
        Player
    }

    // Address of the house and the player
    address payable houseAddress = 0x10469edFf34f31fA1d54dC13907705b70f8DbD83;
    address payable playerAddress;

    // The player choice is encrypted
    bytes32 private encryptedChoice;

    // Moves from enum
    Choices private playerChoice;
    Choices private houseChoice;

    /* Registration Phase */

    // Check betting amount
    modifier checkBet() {
        require(msg.value >= MIN_BET);
        require(totalBet == 0 || msg.value >= totalBet);
        _;
    }

    // Check if the players are registered
    modifier checkRegistration() {
        require(msg.sender != playerAddress);
        _;
    }

    // Register the player
    function registerPlayer()
        public
        payable
        checkBet
        checkRegistration
        returns (uint256)
    {
        playerAddress = msg.sender;
        totalBet = msg.value;
        return 0;
    }

    /* Commit Phase */

    modifier validPlayerRegistered() {
        require(msg.sender == playerAddress);
        _;
    }

    function increaseBet(uint256 amount) public payable {
        if (msg.sender == playerAddress) {
            totalBet += amount; //msg.value ?
        }
    }

    function gamePlay(bytes32 hashChoice)
        public
        validPlayerRegistered
        returns (bool)
    {
        if (encryptedChoice == 0x0) {
            encryptedChoice = hashChoice;
        } else {
            return false;
        }
        return true;
    }

    /* Reveal Phase */

    modifier gameHasBeenPlayed() {
        require(encryptedChoice != 0x0);
        _;
    }

    function ShowAnswer(string memory key)
        public
        validPlayerRegistered
        gameHasBeenPlayed
        returns (Choices)
    {
        // Encrypt the inputted key
        bytes32 keyChoice = sha256(abi.encodePacked(key));

        // Find what side was chosen (L or R)
        Choices LorR = Choices(discoverChoice(key));

        // Verify that the hashed key matches the hash inputted in the gamePlay() function
        // This is what makes the game secure
        if (keyChoice == encryptedChoice) {
            playerChoice = LorR;
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

    function pickRandomSide() public view returns (Choices) {
        uint findHouseChoice = random() % 2;
        if (findHouseChoice == 0) {
            return Choices(0);
        } else {
            return Choices(0);
        }
    }

    function discoverChoice(string memory str) private pure returns (uint256) {
        bytes1 firstCharacter = bytes(str)[0];
        if (firstCharacter == "L") {
            return 0;
        } else {
            return 1;
        }
    }


    // Random Function Referenced From: https://www.geeksforgeeks.org/random-number-generator-in-solidity-using-keccak256/ 
    function random() private view returns (uint) {
        uint randNonce = 1;
        return uint(keccak256(abi.encodePacked(now, msg.sender, randNonce))) % 2;
    }

    /* Results Phase */

    modifier revealEnd() {
        require(
            (playerChoice == Choices.Left || playerChoice == Choices.Right) ||
                (firstRevealTime != 0 &&
                    block.timestamp > firstRevealTime + REVEAL_DEADLOCK) // change unit
        );
        _;
    }

    function findWinner() public revealEnd returns (Results) {
        Results winner;
        if (playerChoice == houseChoice) {
            winner = Results.Player;
        } else {
            winner = Results.House;
        }

        payment(playerAddress, houseAddress, winner);
        reset();
    }

    function payment(address payable playerAddr, address payable houseAddr, Results theWinner) private {
        if (theWinner == Results.Player) {
            houseAddr.transfer(totalBet);
        } else {
            playerAddr.transfer(totalBet);
        }

        payoutPaid = true;
    } 

    modifier paymentGiven() {
        require(
            payoutPaid == true
        );
        _;
    }

    function reset() private paymentGiven {
        totalBet = 0;
        playerAddress = address(0x0);
        playerChoice = Choices.Empty;
        houseChoice = Choices.Empty;
        encryptedChoice = 0x0;
        payoutPaid = false;
    }
}