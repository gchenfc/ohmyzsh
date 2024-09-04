#!/bin/bash

if [ $# -eq 2 ]
  then
    echo "Composing the frames of file ${1}.mp4 at ${2} fps"
  else
    echo "Not enough input args."
    echo "Usage:    ./compose <fileprefix> <take every nth frame>"
    echo "Example:  ./compose ATL_0 100"
    exit 1
fi

set -e # exit on first error

fprefix=$1
fps=$2

# extract images from video
mkdir /tmp/${fprefix}_${fps}
ffmpeg -i ${fprefix}.mp4 -r $fps /tmp/${fprefix}_${fps}/img_%04d.jpg

# overlay images
mkdir /tmp/${fprefix}_movie_${fps}
cp /tmp/${fprefix}_${fps}/img_0001.jpg /tmp/${fprefix}_movie_${fps}/img_0001.jpg
previmg=img_0001.jpg
for f in $(ls /tmp/${fprefix}_${fps}); do
  echo "adding $f..."
  convert /tmp/${fprefix}_movie_${fps}/$previmg /tmp/${fprefix}_${fps}/$f -compose Darken -flatten /tmp/${fprefix}_movie_${fps}/$f
  previmg=$f
done
echo "copying image $f"
cp /tmp/${fprefix}_movie_${fps}/$f ${fprefix}_${fps}_overlay.jpg

# assemble overlayed images into video
ffmpeg -i /tmp/${fprefix}_movie_${fps}/img_%04d.jpg -r ${fps} -vcodec libx264 ${fprefix}_${fps}fps_overlay.mp4
