#!/bin/bash

PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -q -c"

# Prompt for username
echo "Enter your username:"
read USERNAME

# Fetch user information
USER=$($PSQL "SELECT username, games_played, best_game FROM users WHERE username='$USERNAME'")

# Check if user exists
if [[ -z $USER ]]
then
  # New user
  echo "Welcome, $USERNAME! It looks like this is your first time here."
  $PSQL "INSERT INTO users(username) VALUES('$USERNAME')"
else
  # Existing user
  echo $USER | while IFS="|" read USERNAME GAMES_PLAYED BEST_GAME
  do
    echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
  done
fi

# Generate secret number
SECRET_NUMBER=$(( RANDOM % 1000 + 1 ))
NUMBER_OF_GUESSES=0

echo "Guess the secret number between 1 and 1000:"

# Main game loop
while true
do
  read GUESS

  # Validate input
  if [[ ! $GUESS =~ ^[0-9]+$ ]]
  then
    echo "That is not an integer, guess again:"
    continue
  fi

  # Increment number of guesses
  (( NUMBER_OF_GUESSES++ ))

  # Check guess
  if [[ $GUESS -eq $SECRET_NUMBER ]]
  then
    echo "You guessed it in $NUMBER_OF_GUESSES tries. The secret number was $SECRET_NUMBER. Nice job!"
    break
  elif [[ $GUESS -gt $SECRET_NUMBER ]]
  then
    echo "It's lower than that, guess again:"
  else
    echo "It's higher than that, guess again:"
  fi
done

# Update user information in the database
USER_ID=$($PSQL "SELECT user_id FROM users WHERE username='$USERNAME'")
GAMES_PLAYED=$(( $($PSQL "SELECT games_played FROM users WHERE username='$USERNAME'") + 1 ))

$PSQL "UPDATE users SET games_played=$GAMES_PLAYED WHERE user_id=$USER_ID"

BEST_GAME=$($PSQL "SELECT best_game FROM users WHERE username='$USERNAME'")
if [[ -z $BEST_GAME || $NUMBER_OF_GUESSES -lt $BEST_GAME ]]
then
  $PSQL "UPDATE users SET best_game=$NUMBER_OF_GUESSES WHERE user_id=$USER_ID"
fi
