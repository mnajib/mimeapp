#!/usr/bin/env bash
#
# NajibMalaysia <mnajib@gmail.com>
#
# Dependencies:
# - xdg-mime
# - handlr
#
# NOTES:
# - If you've manually changed .desktop files, do:
#   update-desktop-database ~/.local/share/applications/
#   update-mime-database ???
#

printUsage() {
 echo -n "Usage:
   mime-test.sh <file>

 Where the file is a file that we will identify what it's mimetype
 and what is the default application currently configured to open the file with the filetype.
 "
}

#INPUT_FILE="/home/najib/Downloads/Takwim_Hijri_1438H.pdf"
INPUT_FILE=$1
SYS_DOTDESKTOP_DIR="/run/current-system/sw/share/applications"
USR_DOTDESKTOP_DIR="${HOME}/.local/share/applications"
SYS_MIMEAPPS_FILE="/run/current-system/sw/share/applications/mimeinfo.cache" # mimeapps.cache" # system-wide
USR_MIMEAPPS_FILE="${HOME}/.local/share/applications/mimeapps.list" # mimeinfo.cache # user-specific
#USR_MIMEAPPS_FILE="${HOME}/.config/mimeapps.list" # user-specific

# Define the Maybe monad
# The Maybe function is defined to handle only single values of output
Maybe_OLD() {
  local value=$1
  local is_just=$2

  if [ "$is_just" = "true" ]; then
    echo "Just $value"
  else
    echo "Nothing"
  fi
}

# Define the Maybe monad
# The Maybe function is defined to handle both single values and multiple lines of output
Maybe() {
  local value=$1
  local is_just=$2
  local result=""

  if [ "$is_just" = "true" ]; then
    if [ -n "$value" ]; then
      #echo "Just $value"
      result="Just $value"
    else
      #echo "Just"
      result="Just"
    fi
  else
    #echo "Nothing"
    result="Nothing"
  fi

  echo "$result"
}

# Define a function to extract the value from a Maybe
fromMaybe() {
  local maybe=$1
  local default=$2
  local result=""

  if [[ $maybe =~ ^Just ]]; then
    #echo "${maybe:5}"
    result="${maybe:5}"
  else
    #echo "$default"
    result="$default"
  fi

  echo "$result"
}

# Usage:
#   file_exists <file>
file_exists() {
  if [ -f "${1}" ]; then
    Maybe true true
  else
    Maybe false false
  fi
}

#
# Usage:
#   findFileIO "$file_name" "$dir1" "$dir2" "$dir3"
#
#   directories=(/path/to/dir1 /path/to/dir2 /path/to/dir3)
#   file_name="example.txt"
#   file_location=$(find_file "$file_name" "${directories[@]}")
#
readFileIO() {
  local file=$1
  local content=$(cat "$file")
  echo "$content"
}

inputFile() {
  #echo "INPUT_FILE                : ${INPUT_FILE}"
  echo "${INPUT_FILE}"
}

# List match between: mimetype <-> application
# Usage:
#   usrMimeAppsFile
usrMimeAppsFile() {
  echo "${USR_MIMEAPPS_FILE}"
}

# Usage:
#   sysMimeAppsFile
sysMimeAppsFile() {
  echo "${SYS_MIMEAPPS_FILE}"
}

# Location of files (*.desktop) that provide info how to open an application
# Usage:
#   usrDotDesktopDir
usrDotDesktopDir() {
  echo "${USR_DOTDESKTOP_DIR}"
}

# Usage:
#   sysDotDesktopDir
sysDotDesktopDir() {
  echo "${SYS_DOTDESKTOP_DIR}"
}

## To get what is the filetype of a certain file
# Usage:
#   filetype <file>
filetype() {
  #local FILETYPE="$(xdg-mime query filetype "${1}")"
  #echo "${FILETYPE}"

  local file_type
  file_type=$(xdg-mime query filetype "${1}" 2>/dev/null)

  if [ $? -eq 0 ]; then
    #echo "Just $FILETYPE"
    Maybe "$file_type" true
  else
    #echo "Nothing"
    Maybe "" false
  fi
}

#----------------------------------------------------------------------------------

## To get what is the default application to handle/open the file with the filetype
# Usage:
#   defaultAssociatedApp <filemimetype>
defaultAssociatedApp_OLD() {
  local file_type=$1

  #local DEFAULT_APP="$(handlr get "$1")"
  #echo "${DEFAULT_APP}"

  # XXX:
  local default_app="$(handlr get $file_type)"
  if [ "$default_app" ]; then
  #if [ $default_app="$(handlr get $file_type)" ]; then
    echo  $(Maybe "$default_app" true)
    return
  fi
  echo $(Maybe "" false)
}
#
defaultAssociatedApp() {
  local file_type=$1
  local mimeappslist_file=$USR_MIMEAPPS_FILE

  # XXX: xdg-mime query default application/pdf

  while IFS= read -r line; do
    if [[ $line =~ ^\[Default\ Applications\] ]]; then
      in_section=1
    elif [[ $line =~ ^\[ ]]; then
      in_section=0
    elif (( in_section == 1 )); then
      key=${line%%=*}
      value=${line#*=}
      if [[ $key =~ ^$file_type ]]; then
        #apps+=("$value")
        app="$value"
      fi
    fi
  done < "$mimeappslist_file"

  #app=$(echo "${app}" | sed 's/;$//')
  app="${app%;}"
  if [ "$app" ]; then
    echo $(Maybe "$app" true)
    return
  fi
  echo $(Maybe "" false)

  #local default_app="$(handlr get $file_type)"
  #if [ "$default_app" ]; then
  ##if [ $default_app="$(handlr get $file_type)" ]; then
  #  echo  $(Maybe "$default_app" true)
  #  return
  #fi
  #echo $(Maybe "" false)
}

#----------------------------------------------------------------------------------

# other apps that can open/handle the filetype
# Usage:
#   otherAssociatedApps <filemimetype>
otherAssociatedApps() {
  #local OTHER_APPS="$(handlr get "$1")"
  local mime_type=$1
  local mimeappslist_file=$USR_MIMEAPPS_FILE

  #while IFS='=' read -r key value; do
  #  if [[ $key =~ ^$mime_type ]]; then
  #    apps+=("$value")
  #  fi
  #done < "$mimeappslist_file"

  #  if [[ $line =~ ^\[Added\ Associations\] ]]; then
  #  if [[ $line =~ ^\[Default\ Applications\] ]]; then
  #  if [[ $line =~ ^\[Removed\ Associations\] ]]; then
  while IFS= read -r line; do
    if [[ $line =~ ^\[Added\ Associations\] ]]; then
      in_section=1
    elif [[ $line =~ ^\[ ]]; then
      in_section=0
    elif (( in_section == 1 )); then
      key=${line%%=*}
      value=${line#*=}
      if [[ $key =~ ^$mime_type ]]; then
        apps+=("$value")
      fi
    fi
  #done < "$mimeappslist_file"
  done < "$(usrMimeAppsFile)"

  while IFS= read -r line; do
    if [[ $line =~ ^\[Added\ Associations\] ]]; then
      in_section=1
    elif [[ $line =~ ^\[ ]]; then
      in_section=0
    elif (( in_section == 1 )); then
      key=${line%%=*}
      value=${line#*=}
      if [[ $key =~ ^$mime_type ]]; then
        apps+=("$value")
      fi
    fi
  done < "$(sysMimeAppsFile)"

  #printf '%s\n' "${apps[@]}"
  printf '%s\n' "${apps[@]}" | grep -o '[^; ]*'
}

# Usage:
#   printIO <string>
printIO() {
  echo "${1}"
}

indent_text() {
  local text=$1
  local n=$2

  #printf "%*s%s\n" $n "" "$text"

  while IFS= read -r line; do
    printf "%*s%s\n" $n "" "$line"
  done <<< "$text"
}

## To open the file using the default associated application
#echo "Opening file $FILE"
#handlr open ${FILE}

# Define the find_file function with Maybe monad
dirContainFile() {
  local file_name=$1
  local directories=("${@:2}")

  for dir in "${directories[@]}"; do
    if [ -f "$dir/$file_name" ]; then
      #echo $(Maybe "$dir/$file_name" true)
      echo $(Maybe "$dir" true)
      return
    fi
  done

  echo $(Maybe "" false)
}

findFileIO() {
  local file_name="$1"
  local directories=("${@:2}")

  for dir in "${directories[@]}"; do
    if [ -f "$dir/$file_name" ]; then
      #echo "$dir/$file_name"
      echo "$dir"
      return
    fi
  done

  #shift
  #local dirs=("$@")
  #for dir in "${dirs[@]}"; do
  #  if [ -f "$dir/$file_name" ]; then
  #    echo "$dir/$file_name"
  #    return
  #  fi
  #done
  #echo "File not found" >&2
  #return 1
}

findDotDekstopFileIO() {
  local file_name=$1
  local directories=("${@:2}")
  local file_location=$(findFileIO "$file_name" "${directories[@]}")

  if [ -n "$file_location" ]; then
    echo "Found $file_name at $file_location"
    # Do something with the file location here
  else
    echo "$file_name not found in any of the specified directories"
  fi
}

mainIO() {
  # The file in questions
  local iFile="$(inputFile)"
  printIO ""
  printIO "For the file \"${iFile}\":"

  # Check if the file exist
  maybe_exists=$(file_exists "$iFile")
  if [[ $maybe_exists =~ ^Just ]]; then
    exists=$(fromMaybe "$maybe_exists")
    if [ "$exists" = true ]; then
      echo "- File ${iFile} exists."
    else
      echo "- ERR: File ${iFile} does not exist."
    fi
  else
    echo "- ERR: File ${iFile} does not exist."
  fi

  # What is the filetype (mime) of the file
  #local ft=$(filetype "${iFile}")
  local maybe_ft=$(filetype "${iFile}")
  local ft=$(fromMaybe "$maybe_ft" "unknown")
  if [ "$ft" = "unknown" ]; then
    printIO "- ERR: The filetype is unknown."
  else
    printIO "- The filetype is \"${ft}\"."
  fi

  #--------------------------------------------------------------------------------------

  # What is the default application to open the file
  #da=$(defaultAssociatedApp "${ft}")
  #printIO "- The default application for the filetype is \"${da}\"."
  local maybe_defaultApp=$(defaultAssociatedApp "${ft}")
  if [ "$maybe_defaultApp" = "Nothing" ]; then
    printIO "- ERR: Default application for filetype \"${ft}\" is not found"
    #return
  else
    da=$(fromMaybe "$maybe_defaultApp" "")
    printIO "- The default application for filetype \"${ft}\" is \"${da}\"."
  fi

  #--------------------------------------------------------------------------------------

  # Find where is the file that mention how to start the application (*.desktop)
  local directories=("${USR_DOTDESKTOP_DIR}" "${SYS_DOTDESKTOP_DIR}")
  #directory=$(findFileIO "${da}" "${directories[@]}")
  #printIO "- Found \"${da}\" at \"${directory}/\"."
  local maybe_directory=$(dirContainFile "${da}" "${directories[@]}")
  if [ "$maybe_directory" = "Nothing" ]; then
    printIO "- ERR: File \"${da}\" (that defind how to open the default application) is not found."
    #return
  else
    directory=$(fromMaybe "$maybe_directory" "")
    printIO "- Found \"${da}\" at \"${directory}/\"."
  fi

  # What is the contents of the file (*.desktop)
  #printIO "- Here is the contens of \"${directory}/${da}\" file:"
  #printIO "----------------------------------------"
  #printIO "$(readFileIO "$directory/$da")"
  #printIO "----------------------------------------"

  # List of other applications that able to handle the file (the file in questions @ the input file)
  #printIO "  ========================================"
  printIO "- List of other application that can handle the file with filetype \"${ft}\":"
  printIO "    ----------------------------------------"
  olist=$(otherAssociatedApps "$ft")
  indent_text "$olist" 4 # indent the text with 4 spaces
  printIO "    ----------------------------------------"
  #printIO "========================================"
}

#printIO "$(printUsage)"
mainIO
