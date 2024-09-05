# Print execution times
format_ms() {
    local d=$(($1/1000/60/60/24))
    local h=$(($1/1000/60/60%24))
    local m=$(($1/1000/60%60))
    local s=$(($1/1000%60))
    local ms=$(($1%1000))

    ret=""
    if [[ $h > 0 ]]; then
      ret="$ret:${h}h"
    fi
    if [[ $h > 0 || $m > 0 ]]; then
      ret="$ret:$(printf "%02dm" ${m})"
    fi
    if [[ $h > 0 || $m > 0 ]]; then
      ret="$ret:$(printf "%02d.%03ds" ${s} ${ms})"
    else
      ret="$ret:$(printf "%d.%03ds" ${s} ${ms})"
    fi
    echo ${ret:1}
}

function mytimer_preexec() {
  timer=$(($(date +%s)/1000000))
}

function mytimer_precmd() {
  if [ $timer ]; then
    now=$(($(date +%s)/1000000))
    elapsed=$(($now-$timer))
    export RPROMPT="%F{cyan}[ $(format_ms $elapsed) ] %{$reset_color%}"
    unset timer
  fi
}

add-zsh-hook precmd mytimer_precmd
add-zsh-hook preexec mytimer_preexec
