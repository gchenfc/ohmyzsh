#!zsh
dir=$1
fps=${2:-30}
# This code creates a montage of videos
# Usage: montage_videos.sh dir [fps]

root=/tmp/montage_working_dir
rm -r $root
mkdir $root
# First extract videos to frames
echo "USING FFMPEG TO EXTRACT VIDEOS TO FRAMES"
for video in $(ls $dir | sort -g | grep "mp4" | grep -v "montage"); do
  video_name=${video##*/}
  video_name=${video_name%.*}
  mkdir $root/$video_name
  ffmpeg -hide_banner -loglevel error -i $video $root/$video_name/%04d.jpg
  num_imgs=$(ls $root/$video_name | wc -l)
  for i in $(seq -f "%04g" 1 $num_imgs); do
    mkdir -p $root/$i
    # this is specific to the names of the hyperspectral images
    # shortened_nm="${video_name%.*}nm"
    shortened_nm=$video_name
    mv $root/$video_name/$i.jpg $root/$i/$shortened_nm.jpg
  done
done

# Now montage
mkdir $root/all
echo "STARTING MONTAGE"
for i in $(seq -f "%04g" 1 $num_imgs); do
  echo "    frame $i"
  montage -tile x12 -geometry 80x+0+0 $(echo $root/$i/*.jpg(n)) -set label "%t" $root/all/$i.jpg
done

# And finally assemble into video
echo "ASSEMBLING MONTAGE IMAGES INTO VIDEO"
ffmpeg -y -framerate $fps -pattern_type glob -i "$root"'/all/*.jpg' \
  -c:v libx264 -pix_fmt yuv420p $dir/montage.mp4

################################

# It would also be possible to do this using ffmpeg (e.g. see below) I think it's easier to use montage.
: <<'END'
#!/bin/bash

# Create an array of input videos
videos=("video1.mp4" "video2.mp4" "video3.mp4" "video4.mp4")

# Create a string for the filter complex option
filter_complex=""
for i in "${!videos[@]}"; do
  filter_complex+="[$i:v]setpts=PTS-STARTPTS,scale=1280x720[v$i];"
done
filter_complex+="[v0][v1]hstack=inputs=2[out1];"
for i in "${!videos[@]:2}"; do
  filter_complex+="[out$((i-1))][v$i]hstack=inputs=2[out$i];"
done

# Execute ffmpeg command
ffmpeg -i "${videos[0]}" -i "${videos[1]}" "${videos[@]:2}" -filter_complex "$filter_complex" -map "[out$((i-1))]" output.mp4
END
# or
: <<'END'
# Create an array of input videos
videos=("video1.mp4" "video2.mp4" "video3.mp4" "video4.mp4" "video5.mp4" "video6.mp4" "video7.mp4" "video8.mp4" "video9.mp4" "video10.mp4" "video11.mp4" "video12.mp4")

# Calculate the number of rows
rows=$(((${#videos[@]} + 11) / 12))

# Create a string for the filter complex option
filter_complex=""
for i in "${!videos[@]}"; do
  filter_complex+="[$i:v]setpts=PTS-STARTPTS,scale=960x540[v$i];"
done
filter_complex+="[v0][v1][v2][v3][v4][v5][v6][v7][v8][v9][v10][v11]xstack=inputs=12:layout=0_0|960_0|0_540|960_540|0_1080|960_1080[out0];"
for i in "${!videos[@]:12}"; do
  filter_complex+="[out$((i-12))][v$i]xstack=inputs=2:layout=0_0|960_0[out$i];"
done

# Execute ffmpeg command
ffmpeg -i "${videos[0]}" -i "${videos[1]}" "${videos[@]:2}" -filter_complex "$filter_complex" -map "[out$((rows-1))]" output.mp4
END
#######################################

