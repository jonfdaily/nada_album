#!/bin/bash

# Ensure directory argument is provided
if [ -z "$1" ]; then
  echo -e "\033[1;31mUsage: $0 <directory>\033[0m"
  exit 1
fi

# Set the working directory from the argument
DIRECTORY="$1"
ENCODE_COMMENT="MP3 encoding aided by bandNada.com and lame"

# Check if lame is installed
if ! command -v lame &> /dev/null; then
  echo -e "\033[1;31mError: lame is not installed. Please install lame.\033[0m"
  exit 1
fi

# Check if the provided directory exists
if [ ! -d "$DIRECTORY" ]; then
  echo -e "\033[1;31mDirectory $DIRECTORY not found!\033[0m"
  exit 1
fi

# Check if there's an image file in the directory
IMAGE_FILE=$(find "$DIRECTORY" -type f -iname "*.jpg" -print -quit)
if [ -z "$IMAGE_FILE" ]; then
  echo -e "\033[1;31mNo image file found for cover art in the directory.\033[0m"
  echo -e "\033[1;32mWould you like to (c)ontinue w/o an image or (q)uit? (c/q)\033[0m"
  read CONTINUE
  if [ "$CONTINUE" != "c" ]; then
    echo -e "\033[1;32mAdd an image and run again\033[0m"
    exit 1
  fi
fi

# Function to show a spinner while processing
spin() {
  local pid=$!
  local delay=0.1
  local spinstr='|/-\\'
  while ps -p $pid > /dev/null; do
    local temp="${spinstr#?}"
    printf "[%c]  " "$spinstr"
    spinstr=$temp${spinstr%"$temp"}
    sleep $delay
    printf "\r"
  done
}

escape_filename() {
  echo "$1" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | sed 's/[\/\\&]/_/g'
}

# Prompt the user for artist, album, and year information
echo -e "\033[1;32mEnter the name of the artist (leave blank for different artists per track):\033[0m"
read ARTIST
echo -e "\033[1;32mEnter the name of the album:\033[0m"
read ALBUM
echo -e "\033[1;32mEnter the year of the album (e.g., 2021):\033[0m"
read YEAR

ARTIST_SAFE=$(escape_filename "$ARTIST")
ALBUM_SAFE=$(escape_filename "$ALBUM")
MP3_DIR="$DIRECTORY/$ARTIST_SAFE-$ALBUM_SAFE"

# Create 'mp3' directory if it doesn't exist
mkdir -p "$MP3_DIR"

# Loop through all .wav/mp3 files in the provided directory
for AUDIO_FILE in "$DIRECTORY"/*.{wav,mp3}; do
  # Skip if no audio files are found
  if [ ! -f "$AUDIO_FILE" ]; then
    continue
  fi
  
  # Get the base name of the audio file (without extension)
  BASE_NAME=$(basename "$AUDIO_FILE")
  BASE_NAME_NO_EXT="${BASE_NAME%.*}"

  # Prompt the user for song title
  echo -e "\033[1;33mEnter the song title for $BASE_NAME_NO_EXT:\033[0m"
  read SONG_TITLE

  if [ ! "$ARTIST" ]; then
    echo -e "\033[1;33mEnter the name of the artist for $SONG_TITLE:\033[0m"
    read ARTIST_TMP
    ARTIST_SAFE=$(escape_filename "$ARTIST_TMP")
  else
    ARTIST_TMP = ARTIST
  fi

  # Prompt the user for track number
  echo -e "\033[1;33mEnter the track number for $BASE_NAME_NO_EXT (e.g., 01, 02, etc.):\033[0m"
  read TRACK_NUMBER

  # Generate the output MP3 file path with formatted title
  BASE_NAME_SAFE=$(escape_filename "$SONG_TITLE")
  MP3_FILENAME="${TRACK_NUMBER}_${ARTIST_SAFE}_${ALBUM_SAFE}_${BASE_NAME_SAFE}.mp3"
  MP3_FILE="$MP3_DIR/$MP3_FILENAME"
  
  # If the file is .wav, convert it to MP3 using lame
  if [[ "$AUDIO_FILE" == *.wav ]]; then
    lame --quiet --tc "$ENCODE_COMMENT" --ti "$IMAGE_FILE" --tt "$SONG_TITLE" --ta "$ARTIST_TMP" --tl "$ALBUM" --ty "$YEAR" --tn "$TRACK_NUMBER" "$AUDIO_FILE" "$MP3_FILE" &
    spin $!
    echo -e "\033[1;32mConverted $BASE_NAME_NO_EXT to $MP3_FILENAME with metadata and artwork.\033[0m"
  else
    # If it's already an MP3, just tag it with the metadata
    lame --quiet --tc "$ENCODE_COMMENT" --ti "$IMAGE_FILE" --tt "$SONG_TITLE" --ta "$ARTIST_TMP" --tl "$ALBUM" --ty "$YEAR" --tn "$TRACK_NUMBER" "$AUDIO_FILE" "$MP3_FILE" &
    spin $!
    echo -e "\033[1;32mTagged existing MP3 file $BASE_NAME_NO_EXT with metadata and artwork.\033[0m"
  fi
done

# Include cover.jpg in the 'mp3' folder if exists
if [ ! -z "$IMAGE_FILE" ]; then
  cp "$IMAGE_FILE" "$MP3_DIR/cover.jpg"
  echo -e "\033[1;32mAll files converted, tagged, and artwork added successfully!\033[0m"
else
  echo -e "\033[1;32mAll files converted and tagged\033[0m"
fi
