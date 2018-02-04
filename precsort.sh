#!/bin/bash
# Prerequisites: fdupes is needed for duplicate detection, exiv2 for jpg sorting
# Description: find files, create folder with extension name, move files to folder with right extension, for jpg files
# usage: ./precsort.sh {path} {destination}
# example: ./precsort.sh /mnt/recovered/ /mnt/sorted

#set variables
path=$1
IFS=$'\n'
dst=$2
#
#let's start with a clean screen..
clear
# Check syntax
if [[ -z $path || -z $dst ]]
  then
  echo "Missing arguments."
  echo "usage: ./extsort {path} {destination}"
  exit 1
fi
# Check if exiv2 and fdupes are installed, if not.. error out.
if ! [[ -x "$(command -v exiv2)"  || -x "$(command -v fdupes)" ]]
  then
  printf "\n Missing applications!"
  printf "ERROR: exiv2 and/or fdupes missing: install them before running this script\n"
  exit 1
fi
printf "\n-------------------"
printf "\n| Photorec sorter |"
printf "\n-------------------"
printf "\n\n Moving files to ${dst} (This may take a while)..."
# Find non-empty files in path (no point wasting time on 0 byte files)
for i in $(find $path -type f ! -empty)
  do
  #get just the extension (after last .)
  ext=$(echo "$i" | perl -ne 'print $1 if m/\.([^.\/]+)$/')
  if [[ -z "$ext" ]]
  then
    ext="none"
  fi
  mkdir -p $dst/$ext
  #move file to destination, if file exists add number at end (numbered backups)
  mv --backup=t "$i" $dst/$ext
done
printf "Done! \n"
#Loop through the directories and run fdupes on each one of them individually (to avoid OOM if large amount of files)
printf " Clearing out duplicates..."
for dir in $(find $dst/ -mindepth 1 -type d )
  do
  #automatically deletes duplicates, keeps one copy.
  fdupes -rqdN "$dir" > /dev/null
done
printf "Done! \n\n"
#Look for JPG subdirectory (if no jpgs recovered, no point in doing the next steps)
if [[ -d "$dst""/jpg" ]]; then
    printf "\n Trying to rename JPEGs based on exif data (timestamp)..."
    #rename files based on exif timestamp
    exiv2 -q rename -F "$dst"/jpg/* 2>/dev/null
    printf "Done! \n Trying to sort jpeg files based on timestamp data, please wait..."
      for photo in $(find "$dst""/jpg" -type f)
        do
        # Grep for timestamp, if timestamp can be found we get the 4th field, remove blank lines (exif data found, no date found), we set delimiter to ":" and take first field (year)
        # This works for most cameras although some cameras may store timestamps in a different format in which case the folder sorting may not work that great
        year=$(exiv2 $photo 2> /dev/null | grep timestamp | awk '{print $4}' | sed '/^$/d' | cut -d : -f 1)
        # Create a directory per year (skip if already exists).
        mkdir -p $dst/jpg/$year/
        #move file to backup
        mv --backup=t $photo $dst/jpg/$year/ 2>/dev/null
      done
fi
printf "Done! \n\nAll done... Check your destination folder ($dst)! \n\n"
exit 0
