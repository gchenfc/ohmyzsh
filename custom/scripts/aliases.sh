
alias dirsize='sudo du -csh ./*'
# s: don't list recursive
# h: human readable
# c: also print grand total at the end

# command line notification
alias notifyDone='terminal-notifier -sound default -title "Terminal" -message "Done with task!"'

# brew autoupdate off
alias brew2="HOMEBREW_NO_AUTO_UPDATE=1 brew"

# Ninja
alias nj="ninja"

# git log graph
alias gitlogadog="git log --all --decorate --oneline --graph" # todo: add this to git

# rsync options
alias rsync2="rsync -auhtvzP" # archive, update, human-readable, preserve Times, verbose, compress, Partial+Progress

# gitzip - usage: gitzip {zipname}
alias gitzip2="git archive HEAD -o " # only zips committed changes
alias gitzip="git ls-files -z | xargs -0 zip " # zips all changes, but from committed files only

# Python environments
alias pipenv="/Users/gerry/Library/Python/2.7/bin/pipenv"

# Notifications
function notify {
  # Usage: notify "Title" "Description"

  # Notification center
  osascript -e 'display notification "'$2'" with title "'$1'"'
  # Phone
  data='{"value1":"'$1'","value2":"'$2'"}'
  curl -s -X POST -H "Content-Type: application/json" -d $data https://maker.ifttt.com/trigger/shell-notify/with/key/nTvPTwldo1PUXIx6azyE4VDFWKy4vT-uAIEDtm8YDWI > /dev/null
}

# Combine pdfs
# alias combinepdfs="/System/Library/Automator/Combine\ PDF\ Pages.action/Contents/Resources/join.py"
alias combinepdfs='echo "Drag the pdfs onto the CombinePdfs icon on the desktop and it will create a new pdf on the desktop called merged.pdf."'

# sign an executable to dump core upon segfault (gerry-chen.com/blog/2022-04-21.html)
function sign_coredump {
  # Usage: sign_coredump [[executable file]]
  /usr/libexec/PlistBuddy -c "Add :com.apple.security.get-task-allow bool true" tmp.entitlements
  codesign -s - -f --entitlements /tmp/tmp.entitlements $1
}

# Exif data
function find_exif {
  # Usage: find_exif
  files=$(find $1 -type f -iregex ".*\.png" -o -iregex ".*\.jpg" -o -iregex ".*\.jpeg" -o -iregex ".*\.gif" -o -iregex ".*\.webp")
  echo $files
  filesArray=($(echo "$files"))
  for file (${(f)files}) ; do
    echo -n "Processing $file... "
    exiftool $file | grep -v 'ExifTool Version Number\\|Exif Byte Order\\|Exif Version' | grep -q '^Exif '
    if [ $? -eq 0 ]; then
      echo -n "Found EXIF data, removing now... "
      exif_remove $file > /dev/null
      echo "done."
    else
      echo "No exif data found"
    fi
  done
}
function exif_remove {
  # Usage: exif_remove [[filename]]
  exiftool -all= -tagsFromFile @ -ICC_Profile -ColorSpaceTags -Orientation -overwrite_original_in_place $1
}

function to_mp4 {
  # Usage: to_mp4 filename [[output filename]]
  if [ "$#" -lt 1 ] ; then
    echo "Usage: to_mp4 filename [[output filename]]"
    return 1
  fi
  if [ "$#" -lt 2 ] ; then
    out=$(echo "${1%%.*}").mp4
  else
    out=$2
  fi
  ffmpeg -i $1 -c:v libx264 -c:a copy -pix_fmt yuv420p $out
}

function speed_up_video {
  # Usage: speed_up_video filename amt [[output filename]]
  local usage="Usage: speed_up_video filename amt [[output filename]] [[options]]
ex:    speed_up_video infile.mp4 4 outfile_4x.mp4 --font-size 32
Options:
  -n|--no-overlay
    Doesn't overlay the speed multiplier in the bottom-left of the video (overlays by default)
  -s=|--font-size=
    Sets the font size of the overlay (default: 32)
"
  local flag_help flag_overlay
  local font_size=(32)

  # https://zsh.sourceforge.io/Doc/Release/Zsh-Modules.html#index-zparseopts
  # https://gist.github.com/mattmc3/804a8111c4feba7d95b6d7b984f12a53
  # Remember that the first dash is automatically handled, so long options are -opt, not --opt
  zmodload zsh/zutil
  zparseopts -D -E -F -K -- \
    {h,-help}=flag_help \
    {n,-no-overlay}=flag_overlay \
    {s,-font-size}:=font_size ||
    return 1

  [[ -n "$flag_help" ]] && { print -l $usage && return }
  [[ "$#" -lt 2 ]] && { echo $usage && return 1 }
  in=$1
  amt=$2
  default_out=$(echo "${in%%.*}")__${amt}x.mp4 # https://zsh.sourceforge.io/Doc/Release/Expansion.html#Parameter-Expansion
  out=${3:-$default_out}
  font_size=${font_size[-1]#=} # remove leading "=" if present

  # Summarize arg parsing
  echo "Speeding up $in by $amt times and saving as $out"
  echo "Options: overlay=$flag_overlay"
  echo "         font_size=$font_size"

  # Run
  (( pts = 1.0 / $amt ))
  text="drawtext=text='"$amt"x SPEED':fontcolor=white:fontsize=$font_size:box=1:boxcolor=black@0.5:boxborderw=5:x=10:y=h-text_h-10"
  if [ -n "$flag_overlay" ]; then
    ffmpeg -i $in -c:v libx264 -vf "setpts=$pts*PTS" -an -pix_fmt yuv420p $out
  else
    ffmpeg -i $in -c:v libx264 -vf "setpts=$pts*PTS,$text" -an -pix_fmt yuv420p $out
  fi
  echo "saved as $out"
}

function overlay_frames_light() {
  # Start with the first frame as the base image
  cp frame0001.png long_exposure.png

  # Loop through all frames and overlay them on the base image
  for frame in frame*.png; do
      echo $frame
      convert long_exposure.png $frame -evaluate-sequence max long_exposure.png
  done
}

function overlay_frames_dark() {
  # Start with the first frame as the base image
  cp frame0001.png long_exposure_min.png

  # Loop through all frames and overlay them on the base image
  for frame in frame*.png; do
      echo $frame
      convert long_exposure_min.png $frame -evaluate-sequence min long_exposure_min.png
  done
}

function overlay_frames_light_vid() {
  folder="overlay_light"
  # Start with the first frame as the base image
  cp frame0001.png $folder/long_exposure0001.png

  # Initialize frame counter
  counter=2

  # Loop through all frames in numerical order and overlay them on the base image
  for frame in ${(o)$(ls frame*.png)}; do
    # Skip the first frame as it is already copied as the base image
    if [ "$frame" == "frame0001.png" ]; then
      continue
    fi

    # Format counter to have leading zeros for input and output
    printf -v input_counter_str "%04d" $((counter - 1))
    printf -v output_counter_str "%04d" $counter

    echo "Processing $frame"
    convert $folder/long_exposure${input_counter_str}.png $frame -evaluate-sequence max $folder/long_exposure${output_counter_str}.png

    # Increment counter
    ((counter++))
  done

  # Combine the overlay frames into a video
  ffmpeg -framerate 30 -i $folder/long_exposure%04d.png -c:v libx264 -pix_fmt yuv420p long_exposure_light.mp4
}

function overlay_frames_dark_vid() {
  folder="overlay_dark"
  mkdir $folder
  # Start with the first frame as the base image
  cp frame0001.png $folder/long_exposure0001.png

  # Initialize frame counter
  counter=2

  # Loop through all frames in numerical order and overlay them on the base image
  for frame in ${(o)$(ls frame*.png)}; do
    # Skip the first frame as it is already copied as the base image
    if [ "$frame" = "frame0001.png" ]; then
      continue
    fi

    # Format counter to have leading zeros for input and output
    printf -v input_counter_str "%04d" $((counter - 1))
    printf -v output_counter_str "%04d" $counter

    echo "Processing $frame"
    convert $folder/long_exposure${input_counter_str}.png $frame -evaluate-sequence min $folder/long_exposure${output_counter_str}.png

    # Increment counter
    ((counter++))
  done

  # Combine the overlay frames into a video
  ffmpeg -framerate 30 -i $folder/long_exposure%04d.png -c:v libx264 -pix_fmt yuv420p long_exposure_dark.mp4
}


function dxf2svg {
  # Usage: dxf2svg filename [[output filename]]
  if [ "$#" -lt 1 ] ; then
    echo "Usage: dxf2svg filename [[output filename]]"
    return 1
  fi
  if [ "$#" -lt 2 ] ; then
    out=$(echo "${1%.*}").svg
  else
    out=$2
  fi
  python /Applications/Inkscape.app/Contents/Resources/share/inkscape/extensions/dxf_input.py $1 > $out
}

# Virtual Terminal

alias virtual_terminal="socat PTY,link=$HOME/myserialline,raw,echo=0  EXEC:'ssh localhost socat - /dev/ttyS0'"

# GraphicsMagick
unalias gm # git-merge

# Audio recorder backup
function backup_audio_recorder {
  # Usage: backup_audio_recorder [[-y|--yes]]
  # Backs up audio recordings from the SD card to an icloud-backed-up folder
  # Deletes the recordings from the SD card
  # Moves the recordings from the SD card to the 'old' folder backup on the SD card
  # If the -y or --yes flag is passed, it will skip the confirmation prompts

  confirm=true
  if [[ $1 =~ ^[Yy]$ ]] || [[ $1 == "-y" ]] || [[ $1 == "--yes" ]]; then
    confirm=false
  fi

  src="/Volumes/NO NAME/RECORD"
  dest="/Users/gerry/Library/Mobile Documents/com~apple~CloudDocs/Recordings/"
  if $confirm; then
    echo -n "Backing up audio recordings from $src to $dest.  Ok? [y/n] "
    read -q
    if [[ $REPLY =~ ^[Yy]$ ]] ; then
      rsync -avzP $src/*.MP3 $dest
    fi

    echo -n "\nDeleting audio recordings from the 'old' folder backup on the SD card.  Ok? [y/n] "
    read -q
    if [[ $REPLY =~ ^[Yy]$ ]] ; then
      rm $src/../old/
    fi

    echo -n "\nMoving audio recordings from the SD card to the 'old' folder backup on the SD card.  Ok? [y/n] "
    read -q
    if [[ $REPLY =~ ^[Yy]$ ]] ; then
      mv $src/* $src/../old
    fi
    echo
  else
    echo "Backing up audio recordings from $src to $dest."
    rsync -avzP $src/*.MP3 $dest
    echo "Deleting audio recordings from the 'old' folder backup on the SD card."
    rm $src/../old/
    echo "Moving audio recordings from the SD card to the 'old' folder backup on the SD card."
    mv $src/* $src/../old
  fi

  echo "Done.  Opening $dest and $src."
  sleep 1
  open $dest
  open $src
}

# Socat mirrors serial device on RAW AIR pi to local machine
alias air_socat='socat PTY,link=$HOME/myserialline,raw,echo=0  EXEC:"ssh raw_air /usr/bin/socat - /dev/ttyACM0"'

# youtube-dl aliases
alias youtube_download_video=youtube-dl

function youtube_segment_download {
  # Downloads a segment of a long youtube video.
  # Usage: download_segment_of_long_youtube_video [-s start_time] [-e duration] [-o output_filename] [-f format] youtube_url
  # Help:  download_segment_of_long_youtube_video -h

  if [[ "$#" -lt 1 ]] || [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
    echo "Usage: download_segment_of_long_youtube_video [-s start_time] [-e duration] [-o output_filename] youtube_url"
    echo "Defaults:"
    echo "  start_time: 0"
    echo "  duration: 10"
    echo "  output_filename: output.mp4"
    echo "  format: best"
    echo "      To see available formats, run \`youtube-dl -F youtube_url\` and look at the \"format code\" column (should be numbers like 96, 105, ...)."
    echo "      See also \`man youtube-dl\` the \"FORMAT SELECTION\" section."
    return 1
  fi
  # ffmpeg -ss "01:58:05.1" -i $(youtube-dl https://www.youtube.com/watch\?v\=Q05Ic7cS720\&t\=7085s\&ab_channel\=UCSBBrenSchool -f96 -g) -t 0:0:5.7 -c copy output.mp4 -y
  # Parse args, and exit on the first non-option argument
  while [[ "$#" -gt 0 ]]; do
    case $1 in
      -s|--start-time) start_time="$2"; shift ;;
      -e|--duration) duration="$2"; shift ;;
      -o|--output-filename) output_filename="$2"; shift ;;
      -f|--format) format="$2"; shift ;;
      *) break ;;
    esac
    shift
  done
  # Any extra arguments are forwarded to `youtube-dl`.  If 1 arg, then nominal and proceed.  Else, ask for confirmation.
  if [[ "$#" -ne 1 ]]; then
    echo "Warning: more arguments than expected."
    echo "Parsed:"
    echo "  start_time: $start_time"
    echo "  duration: $duration"
    echo "  output_filename: $output_filename"
    echo "  format: $format"
    echo "  arguments that are going to be passed to youtube-dl (including youtube url): $@"
    echo ""
    echo "Continue with these arguments? [y/n]"
    read -q
    if [[ ! $REPLY =~ ^[Yy]$ ]] ; then
      echo "Exiting."
      return 1
    fi
    return 1
  fi
  ffmpeg -ss "${start_time:-0}" -i $(youtube-dl $@ -f${format:-best} -g) -t ${duration:-10} -c copy ${output_filename:-output.mp4}
}

# Add audiobook track metadata
function audiobook_metadata {
  echo "Usage: audiobook_metadata [album]"
  IFS=$'\n'       # make newlines the only separator
  total_files=$(ls *.mp3 | wc -l)
  count=1
  for f in $(ls *.mp3 | sort -V); do
      # Specify the album if an argument is given
      if [ "$#" -eq 1 ] ; then
        ffmpeg -i "$f" -c:a copy -metadata track="$count/$total_files" -metadata album="$1" "temp_$f" && mv "temp_$f" "$f"
      else
        ffmpeg -i "$f" -c:a copy -metadata track="$count/$total_files" "temp_$f" && mv "temp_$f" "$f"
      fi
      count=$((count+1))
  done
  echo "Usage: audiobook_metadata [album]"
  unset IFS
}

alias ffmpeg_quiet="ffmpeg -v quiet -stats"