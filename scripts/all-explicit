#!/bin/bash

# This script is designed to help you clean your computer from unneeded
# packages. The script will find all packages that no other installed package
# depends on. It will output this list of packages excluding any you have
# placed in the ignore list. You may browse through the script's output and
# remove any packages you do not need.

# Enter groups and packages here which you know you wish to keep. They will
# not be included in the list of unrequired packages later.
ignoregrp="base base-devel"
ignorepkg=""

# Temporary file locations
tmpdir=/tmp
ignored=$tmpdir/ignored
installed=$tmpdir/installed

# Generate list of installed packages and packages you wish to keep.
echo $(pacman -Sg $ignoregrp | awk '{print $2}') $ignorepkg | tr ' ' '\n' | sort | uniq > $ignored
pacman -Qq | sort > $installed

# Do not loop packages you are keeping
loop=$(comm -13 $ignored $installed)

# Check each remaining package. If package is not required by anything and
# is not on your ignore list, print the package name to the screen.
for line in $loop; do
  check=$(pacman -Qi $line | awk '/Required By/ {print $4}')
  if [ "$check" == 'None' ]; then echo $line; fi
done

# Clean up $tmpdir
rm $ignored $installed
