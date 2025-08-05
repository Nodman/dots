music=$(osascript ~/applescript/spotify.scpt)

if [[ $music ]];
then
  if [ -z "$1" ];
  then
    echo "${music}"
  else
    echo "${music//?/ }"
  fi;
fi;
