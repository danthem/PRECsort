# PRECsort
The purpose of this script is to assist in going through data recovered via Photorec (https://www.cgsecurity.org/wiki/PhotoRec), this data will all be unsorted in recup_XX dirs which is not very easy to go through manually.

The script will take two arguments, a source directory ($1) and a destination directory ($2), the source directory should be the destination directory that you used for Photorec and destination directory should be a new directory where you want to move the sorted data. 

For each extension found, a subdirectory will be created in your destination directory and files with be placed in the directory matching its extension. Only files >0 bytes will be moved, we'll ignore empty files. Once all files are moved, fdupes is used to clear out any detected duplicates. If there were any JPG files recovered, exiv2 will be called to rename JPG files based on their EXIF timestamp and then further sorted by year (where possible).

*Requirements: exiv2 and fdupes needs to be installed on system. (```apt-get install exiv2 fdupes```   or ```pacman -S exiv2 fdupes``` )

*Syntax: ```bash precsort.sh {source} {destination}```

*Example:```bash precsort.sh /mnt/recovered/ /data/sorted/```

GIF of script in action:
![](precsort2.gif)
