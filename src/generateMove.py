import hashlib

def main():
    validMove = False
    playerMove = None

    # Receive a valid move from the player
    while validMove is False:
        print("""
        *** What side will you pick? ***
        (L)eft
        (R)ight
        """)
        playerMove = input()
        if playerMove != "L" and playerMove != "R":
            print("Invalid input, try again.")
            continue
        else:
            break
            
    # Enter a password, A.K.A. salt to the hash
    print("""
        *** Input a password! ***
    """)
    password = input()

    # Print out the key and hashed key values
    print("\n----------------------\n")
    key = playerMove + "-" + password
    hash = "0x" + hashlib.sha256(key.encode()).hexdigest()
    print('Key  : "' + key + '"')
    print('Hash : "' + hash + '"')
    print("""
    First input the hash value into the "MakeMove" function.
    Once you're ready to reveal the answer input the key into the "ShowAnswer" function!
    """)


if __name__ == "__main__":
    main()