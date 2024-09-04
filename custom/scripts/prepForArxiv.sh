#!/bin/zsh
# This script sanitizes a latex project for an arXiv submission.
# Specifically, it "sanitizes" the project by removing any files that are not used in compilation.
# 
# Usage:
#   cd latex_folder_root
#   ./prepForArxiv.sh
#   (generates a zip archive in /tmp/archive.zip)
# 
# It is not exhaustive, but it is pretty good and should work for most cases.
# Also, it does not remove comments within the latex source.
# It was written to be run on mac with gsed = GNU sed, but with grep = Mac/BSD grep, but should
#   require minimal changes to work with Linux.
# Author: Gerry Chen

# first copy all the .tex files over to a temporary folder
dir='/tmp/stagingarea/'
rm -r $dir
mkdir $dir

for f in $(find .); do
  # copy all .tex files
  if [[ "$f" == *".tex"* ]]; then
    mkdir -p $dir$(dirname $f) && cp $f "$_"
    newf=$dir$f
    gsed -i 's/\.eps/-eps-converted-to\.pdf/g' $newf
    # gsed -Ei 's=\{[^\{]*/([^/\{]*)\.svg\}=\{svg-inkscape/\1-end.svg\}=g' $newf # TODO
    echo $newf
    grep "^[^%]*\.svg" $newf
  fi
  if [[ "$f" == *".bbl"* ]]; then
    cp $f $dir/$(basename $f)
  fi
  if [[ "$f" == *".cls"* ]]; then
    cp $f $dir
  fi
done

# Now check every file in this folder to see if its filename is reference in any tex files.
dir2='/tmp/stagingarea2/'
rm -r $dir2
mkdir $dir2

for f in $(find .); do
  fname=$(basename $f)

  if [[ "$f" == *".sty"* ]]; then
    # remove extension
    fname=$(echo $fname | gsed 's/\.[^.]*$//')
  fi
  if [[ "$f" == *".tex"* ]]; then
    # remove extension
    fname=$(echo $fname | gsed 's/\.[^.]*$//')
  fi

  # Loop over files only
  if [[ -f "$f" ]]; then
    fnameescaped=$(echo $fname | gsed 's/\./\\./g')
    # check if this file is referenced anywhere in the .tex files
    if [[ $(grep -r "^[^%]*$fnameescaped" $dir) ]]; then
      grep -r "^[^%]*$fname" $dir
      echo $(dirname $f) "   ----    " $f
      # cp $f $dir2$f
      mkdir -p $dir2$(dirname $f) && cp $f "$_"
    fi
  fi
done

# Finally, clean up by merging the two folders, zipping, and cleaning up.
cp -rn $dir2/* $dir
cd $dir
rm /tmp/archive.zip
zip -r /tmp/archive.zip .

ls $dir

echo "Output zip file is located at /tmp/archive.zip"
