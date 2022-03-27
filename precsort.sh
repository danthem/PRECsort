#!/bin/bash
# Author: Daniel Elf - github.com/danthem
# Prerequisites: fdupes is needed for duplicate detection, exiftool renaming and sorting files based on exif data
# Description: find files, create directory with extension name, move file to matching directory.
# Purpose: To be used after restoring data with photorec (https://www.cgsecurity.org/wiki/PhotoRec)
# Usage: ./precsort.sh {path} {destination}
# Example: ./precsort.sh /mnt/recovered/ /mnt/sorted

#set variables
src=$1
dst=$2
# vars that can be used to change font color
white=$(tput setaf 7)
blue=$(tput setaf 6)
green=$(tput setaf 2)
yellow=$(tput setaf 3)
red=$(tput setaf 1)
normal=$(tput sgr0) # default color

### Functions ###
function syntaxcheck(){
# Checks syntax and ensures dependencies are installed
  if [[ -z "${src}" || -z "${dst}" ]]; then
      printf "${red}Error:${normal}"
      echo "Missing arguments."
      echo "Usage: ./extsort {source} {destination}"
      echo "Where \"source\" is your (unsorted) photorec destination directory and destination is where you want the sorted results."
      exit 1
  elif [[ "${src}" == "${dst}" ]]; then
      printf "${red}Error:${normal}"
      echo "You can't use the same source and destination paths."
      echo "Usage: ./extsort {source} {destination}"
      echo "Where \"source\" is your (unsorted) photorec destination directory and destination is where you want the sorted results."
      exit 1
  fi
  # Check if exiftool and fdupes are installed, if not.. error out.
  if ! [[ -x "$(command -v exiftool)"  || -x "$(command -v fdupes)" ]]
    then
    printf "\n${red}ERROR:${yellow} Missing dependencies\n"
    printf "${white}exiftool${normal} and/or ${white}fdupes${normal} missing: install them before running this script\n"
    exit 1
  fi
}

function spinner(){
  # This function takes care of the spinner used for long-lasting tasks. A cosmetic feature.
    local pid=$!
    local spinstr='|/-'\\
    while [ -d /proc/"$pid" ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep 0.75
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

function movefiles(){
  find "${src}" -type f ! -empty | while read -r file; do
  # get just the file extension, if none.. set $ext to none
  if [[ "${file}" == *"."* ]]; then
    ext=$(echo "${file}" | awk -F . '{print $NF}')
  else
    ext="none"
  fi
  mkdir -p "${dst}"/"${ext}"
  # move file to destination, if file exists add number at end (numbered backups)
  mv --backup=t "${file}" "${dst}"/"${ext}"
done
}

function finddupes(){
# Function for finding duplicates. we manage one sub directory at the time as to avoid runing OOM
# If you run OOM anyways, consider modifying script to skip 'finddupes' or run script on a more powerful machine
  find "${dst}"/ -mindepth 1 -type d | while read -r dir; do
    fdupes -rqdN "$dir" > /dev/null
  done
}

function exifrename(){
  #Function for using exiftool to rename and sorted based on timestamps
  ext=$1
  # I've opted to always just look for date data, looking for things like artist/track/album etc (for music) can result in bad filenames 
  # You can modify this as you see fit, see the great documentation at https://exiftool.org/exiftool_pod.html
  exiftool -api largefilesupport=1 -q -r -ext "${ext}" -d "${dst}"/"${ext}"/%Y/%Y_%m_%dT%H%M%%-c.%%le -filename="${dst}"/"${ext}"/undetermined_date/%f%+c.%e '-filename<CreateDate' "${dst}"/"${ext}"/ 2> /dev/null
}


### EXECUTION STARTS HERE ###
clear
printf "==================="
printf "\n| ${yellow}Photorec sorter${normal} |"
printf "\n==================="
printf "\nStart time: ${white}%s${normal}" "$(date +'%T (%D)')"
printf "\nSource dir: ${blue}%s${normal}" "${src}"
printf "\nDestination dir: ${blue}%s${normal}\n"  "${dst}"
printf "%s" "--------------"

# Find non-empty files in path (no point wasting time on 0 byte files)
printf "\n > Moving files from source to destination..."
movefiles &
spinner
printf " ${green}Done!${normal}\n"

# Loop through the directories and run fdupes on each one of them individually (to avoid OOM if large amount of files)
printf " > Clearing out duplicates..."
finddupes &
spinner
printf " ${green}Done!${normal}\n"

# Here we can call for exiftool to check certain extension directories for exif data and rename/sort based on it
# I've chosen to do this for jpg, mov, mp4 and psd files as I've had good success with that. You can add more extensions as you want by adding them to the for loop below (space separated).
for extension in jpg mov mp4 psd; do
  if [[ -d "$dst"/"${extension}" ]]; then
    printf " > Renaming and sorting %s files based on exif timestamp... " "$extension"
    # If 'extension' was found, pass it on to 'exifrename'-function for rename and sort
    exifrename "${extension}" &
    spinner
    printf " ${green}Done!${normal}\n"
  fi
done

printf "%s" "--------------"
printf "\nAll done!\n"
printf "End time: ${white}%s${normal}\n\n" "$(date +'%T (%D)')"
exit 0
