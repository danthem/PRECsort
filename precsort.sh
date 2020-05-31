#!/bin/bash
# Prerequisites: fdupes is needed for duplicate detection, exiv2 for jpg sorting
# Description: find files, create directory with extension name, move file to matching directory.
# Purpose: To be used after restoring data with photorec (https://www.cgsecurity.org/wiki/PhotoRec)
# Usage: ./precsort.sh {path} {destination}
# Example: ./precsort.sh /mnt/recovered/ /mnt/sorted

#set variables
path=$1
dst=$2
# vars that can be used to change font color
white=$(tput setaf 7)
blue=$(tput setaf 6)
green=$(tput setaf 2)
yellow=$(tput setaf 3)
red=$(tput setaf 1)
normal=$(tput sgr0) # default color
#
#let's start with a clean screen..
clear
# Check syntax and dependencies
if [[ -z "${path}" || -z "${dst}" ]]; then
    printf "${red}Error:${normal}"
    echo "Missing arguments."
    echo "Usage: ./extsort {path} {destination}"
    echo "Where \"path\" is your photorec destination direction and destination is where you want the sorted results."
    exit 1
elif [[ "${path}" == "${dst}" ]]; then
    printf "${red}Error:${normal}"
    echo "You can't use the same source and destination paths."
    echo "Usage: ./extsort {path} {destination}"
    echo "Where \"path\" is your photorec destination direction and destination is where you want the sorted results."
    exit 1
fi
# Check if exiv2 and fdupes are installed, if not.. error out.
if ! [[ -x "$(command -v exiv2)"  || -x "$(command -v fdupes)" ]]
  then
  printf "\nMissing dependencies!"
  printf "${red}ERROR:${yellow} ${white}exiv2${normal} and/or ${white}fdupes${normal} missing: install them before running this script\n"
  exit 1
fi

function spinner(){
  # This function takes care of the spinner used for long-lasting tasks
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

printf "==================="
printf "\n| ${yellow}Photorec sorter${normal} |"
printf "\n==================="
printf "\nStart time: ${white}%s${normal}" "$(date +'%T (%D)')"
printf "\nSource dir: ${blue}%s${normal}" "${path}"
printf "\nDestination dir: ${blue}%s${normal}\n"  "${dst}"
printf "%s" "--------------"
printf "\n > Moving files from source to destination..."
# Define the spinner function, just cosmetic but it's nice to let user know that something is happening

# Find non-empty files in path (no point wasting time on 0 byte files)
find "${path}" -type f ! -empty | while read -r file; do
  # get just the file extension, if none.. set $ext to none
  if [[ "${file}" == *"."* ]]; then
    ext=$(echo "${file}" | awk -F . '{print $NF}')
  else
    ext="none"
  fi
  mkdir -p "${dst}"/"${ext}"
  # move file to destination, if file exists add number at end (numbered backups)
  mv --backup=t "${file}" "${dst}"/"${ext}"
done &
spinner
printf " ${green}Done!${normal}\n"
# Loop through the directories and run fdupes on each one of them individually (to avoid OOM if large amount of files)
printf " > Clearing out duplicates..."
find "${dst}"/ -mindepth 1 -type d | while read -r dir; do
  # automatically deletes duplicates, keeps one copy.
  fdupes -rqdN "$dir" > /dev/null
done &
spinner
printf " ${green}Done!${normal}\n"
# Look for JPG subdirectory (if no jpgs recovered, no point in doing the next steps)
if [[ -d "$dst""/jpg" ]]; then
    printf " > Renaming JPGs based on exif timestamp... "
    #rename files based on exif timestamp
    exiv2 -q rename -F "${dst}"/jpg/* 2>/dev/null &
    spinner 
    printf "${green}Done!${normal}\n > Sorting JPGs based on exif timestamp... "
      find "${dst}""/jpg" -type f | while read -r photo; do
        # Grep for timestamp, if timestamp can be found we get the 4th field, remove blank lines (exif data found, no date found), we set delimiter to ":" and take first field (year)
        # This works for most cameras although some cameras may store timestamps in a different format in which case the directory sorting may not work that great
        year=$(exiv2 "${photo}" 2> /dev/null | grep timestamp | awk '{print $4}' | sed '/^$/d' | cut -d : -f 1)
        # Create a directory per year (skip if already exists).
        mkdir -p "${dst}"/jpg/"${year}"/
        #move file to backup
        mv --backup=t "${photo}" "${dst}"/jpg/"${year}"/ 2>/dev/null
      done &
      printf " ${green}Done!${normal}\n"
      spinner
fi
printf "%s" "--------------"
printf "\nAll done!\n"
printf "End time: ${white}%s${normal}\n\n" "$(date +'%T (%D)')"
exit 0
