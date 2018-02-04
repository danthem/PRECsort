# PRECsort
Simple shell script to sort the result from Photorec recovery.

Sorts the data from your recup_XX dirs and puts them in to folders based on extension. It also attempts to rename jpeg files based on exif data and move them in to subfolders based on that.

*Requirements: exiv2 and fdupes needs to be installed on system. (```apt-get install exiv2 fdupes```   or ```pacman -S exiv2 fdupes``` )

*Syntax: ```./precsort.sh {source} {destination}```

*Example:```./precsort.sh /mnt/recovered/ /mnt/sorted/```


