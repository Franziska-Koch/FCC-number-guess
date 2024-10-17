#!/bin/bash

PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

# get user information or create a new user
GET_USER_INFO() {
    echo "Enter your username:"
    read USERNAME

    # check if user exists in the database
    USER_INFO=$($PSQL "SELECT user_id, games_played FROM users WHERE username = '$USERNAME';")
    
    if [[ -z $USER_INFO ]]; then
        echo "Welcome, $USERNAME! It looks like this is your first time here."
        $PSQL "INSERT INTO users (username, games_played) VALUES ('$USERNAME', 0);"
        USER_ID=$($PSQL "SELECT user_id FROM users WHERE username = '$USERNAME';")
        BEST_GAME=0
    else
        USER_ID=$($PSQL "SELECT user_id FROM users WHERE username = '$USERNAME';")
        GAMES_PLAYED=$($PSQL "SELECT games_played FROM users WHERE user_id=$USER_ID;")
        BEST_GAME=$($PSQL "SELECT MIN(num_guesses) FROM games WHERE user_id = $USER_ID;")
        
        if [[ -z $BEST_GAME ]]; then
            BEST_GAME=0
        fi
        
        echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
    fi
}

# start the game
PLAY_GAME() {
    SECRET_NUMBER=$((RANDOM % 1000 + 1))
    NUM_GUESSES=0

    echo "Guess the secret number between 1 and 1000:"
    
    while true; do
        read GUESS

        # check if input is an integer
        if ! [[ $GUESS =~ ^[0-9]+$ ]]; then
            echo "That is not an integer, guess again:"
            continue
        fi

        ((NUM_GUESSES++))

        if (( GUESS < SECRET_NUMBER )); then
            echo "It's higher than that, guess again:"
        elif (( GUESS > SECRET_NUMBER )); then
            echo "It's lower than that, guess again:"
        else
            echo "You guessed it in $NUM_GUESSES tries. The secret number was $SECRET_NUMBER. Nice job!"
            break
        fi
    done

    # update database tables
    $PSQL "INSERT INTO games (user_id, num_guesses) VALUES ($USER_ID, $NUM_GUESSES);"
    $PSQL "UPDATE users SET games_played = games_played + 1 WHERE user_id = $USER_ID;"
}

GET_USER_INFO
PLAY_GAME