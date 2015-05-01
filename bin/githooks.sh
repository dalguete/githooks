#!/bin/bash
#
# Modify the Git Hooks structure, to enable chain calls and external/tracked hook files
# Author: Daniel Dalgo <dalguete@gmail.com>
#
# Utility used to enable some particular capabilities when using git hooks, as
# chaining support and load of versioned hook files inside the repo. Your defined
# hooks will be preserved, but will live in a more adequate place.
#
# USAGE OPTIONS
# -------------
#  [--status|-s [HOOKNAME FILENAME] [-t]]
#     Display the statu of the current struture. When no option defined for the
#     command, this is the default one.
#
#  --init
#     Initializes the structure.
#
#  --destroy
#     Revert the structure to its normal form.
#
#  --add|-a HOOKNAME FILENAME [--do-edit] [-t]
#     Add a new script for a given hook.
#
#  --edit|-e HOOKNAME FILENAME [-t]
#     Edit a script for a given hook.
#
#  --delete|-d HOOKNAME FILENAME [-t]
#     Remove a script for a given hook.
#
################################################################################

set -eu

# Main vars
MAIN_FUNCTION=
ARGS=()
# TODO: Change the approach on flag options, to prevent an explosion
#       when more of these appear.
DO_EDIT=
FROM_TRACKEDHOOKS_FOLDER=

# Name of the trackedhooks/ folder
TRACKEDHOOKS_FOLDER_NAME='trackedhooks'

if [ -z `which git` ]; then
  echo -e >&2 \
  "Git is not installed. Can't continue."

  exit 1
fi

# TODO: use 'local' in fucntion names

# Function used to print the usage message
print_usage() {
  echo -e >&2 \
  " usage: $0 [--status|-s [HOOKNAME FILENAME] [-t]]\n" \
  "usage: $0 --init\n" \
  "usage: $0 --destroy\n" \
  "usage: $0 --add|-a HOOKNAME FILENAME [--do-edit] [-t]\n" \
  "usage: $0 --edit|-e HOOKNAME FILENAME [-t]\n" \
  "usage: $0 --delete|-d HOOKNAME FILENAME [-t]"

  exit 1
}

# Function used to print the no git dir found message
_no_git_dir() {
  echo -e >&2 \
  "No '.git' directory could be found. Is this inside a git repo?"

  exit 1
}

# Helper function used to obtain the .git directory from the current position.
_find_git_dir () {
  cwd=`pwd`

  while [ ! -d "$cwd/.git" ] && [ "x$cwd" != x/ ]; do
    cwd=`dirname "$cwd"`
  done

  if [ ! -d "$cwd/.git" ] ; then
    _no_git_dir
  fi

  echo "$cwd/.git"
}

# Path to the .git directory
GIT_DIR=$(_find_git_dir)

# Helper function used to determine if the new git hooks space has been initialized.
_is_ready() {
  if [ -f "$GIT_DIR/hooks/_.sh" ]; then
    echo 1
  else
    echo 0
  fi
}

# Helper function used to obtain the trackedhooks/ directory from the current position.
_find_trackedhooks_dir () {
  cwd=`pwd`

  # The folder is expected to be one level above, that's why ../ is used
  if [ -d "$cwd/../$TRACKEDHOOKS_FOLDER_NAME" ] ; then
    # Returns a path with no ../ mention in it.
    readlink -f "$cwd/../$TRACKEDHOOKS_FOLDER_NAME"
  fi
}

# Path to the trackedhooks directory
TRACKEDHOOKS_DIR=$(_find_trackedhooks_dir)

# Helper function used to return a list with all available git hooks
_git_hooks() {
  # It's a bit odd using the man page to get all available hooks, but I couldn't find
  # a better way. If you can, please help me fix this.
  # TODO: test in OSX
  man githooks | col -b | sed -nr '/^\s{3}[[:alnum:]-]*$/p' | awk '{print $1}' | tr '\n' ' '
}

# Function used to set the main function to perform
is_main_function_set() {
  if [ "$MAIN_FUNCTION" != "" ]; then
    print_usage
  fi
}

# Function used to ensure there are no conflicts in the logic of parameters passed
_check_conflicts() {
  # Helper counter
  args_count=${#ARGS[@]}

  # TODO: as you can see, the flags tests are set in different conditions, as a helper
  #       for the future cleaning process, when flag will be handled in a clever way,
  #       like arguments.
  case "$MAIN_FUNCTION" in
    status)
      if [[ $args_count -ne 0 && $args_count -ne 2 ]]; then
        print_usage
      fi
      if [[ "$DO_EDIT" != "" ]]; then
        print_usage
      fi
      ;;

    init|destroy)
      if [[ $args_count -gt 0 ]]; then
        print_usage
      fi
      if [[ "$DO_EDIT" != "" || "$FROM_TRACKEDHOOKS_FOLDER" != "" ]]; then
        print_usage
      fi
      ;;

    add)
      if [[ $args_count -ne 2 ]]; then
        print_usage
      fi
      ;;

    edit|delete)
      if [[ $args_count -ne 2 ]]; then
        print_usage
      fi
      if [[ "$DO_EDIT" != "" ]]; then
        print_usage
      fi
      ;;

    *)
      print_usage
      ;;
  esac
}

# Parse all the arguments passed to the program
# TEMP needed as the `eval set --' would nuke the return value of getopt.
TEMP=`getopt -o s::a:e:d:t -l status::,init,destroy,add:,edit:,delete:,do-edit -q -- "$@"`

# TODO: Correct this to make --status the default option.
# TODO: Check how the default param for things like status work. Test the = (equals) 
# after long name options.
if [ $? != 0 ] ; then 
  print_usage
fi

# Note the quotes around $TEMP: they are essential!
eval set -- "$TEMP"

# Set a param as default
if [ $1 = "--" ] ; then 
  eval set -- "-l $TEMP"
fi

echo "$@"
# Process all input data
while [ $# -gt 0 ]
do
  case "$1" in
    -s|--status)  # Display the status.
      is_main_function_set
      MAIN_FUNCTION="status"
      ;;

    --init)  # Initializes the githooks space.
      is_main_function_set
      MAIN_FUNCTION="init"
      ;;

    --destroy)  # Restores the git hooks space to its natural form.
      is_main_function_set
      MAIN_FUNCTION="destroy"
      ;;

    -a|--add)  # Add a new hook file entry.
      is_main_function_set
      MAIN_FUNCTION="add"
      ;;

    --do-edit)  # Open the favorite editor after creating the hook file entry.
      DO_EDIT=1
      ;;

    -e|--edit)  # Edit hook file entry.
      is_main_function_set
      MAIN_FUNCTION="edit"
      ;;

    -d|--delete)  # Delete hook file entry.
      is_main_function_set
      MAIN_FUNCTION="delete"
      ;;

    -t)  # Indicates it should process the trackedhooks/ folder.
      FROM_TRACKEDHOOKS_FOLDER=1
      ;;

    --)	# This is not considered
      ;; 

    *)	# Anything trapped here is considered as an argument
      if [ -z "$1" ]; then
        # Empty data is discarded.
        shift
        continue;
      fi

      # TODO: Use the string concatenation instead of this complicated indexes approach
      # to add new items
      last_index=(${!ARGS[@]})
      last_index=${last_index[@]: -1}
      if [ -z "$last_index" ]; then
        last_index=0
      else
        ((last_index+=1))
      fi

      ARGS[$last_index]=$1
      ;;
  esac

  shift
done

# Ensure there are no conflicts in the logic of parameters passed
_check_conflicts

# Display the status of the current git hooks structure.
status() {
  # Get the
  echo "${ARGS[1]}";
}

# Function used to return the trigger script
_get_trigger_script() {
  # TODO: Finish the _.sh script
  cat << EOL
#!/bin/bash
#
# DO NOT MODIFY. FILE AUTOMATICALLY GENERATED!!!
#
mundo
carajo
EOL
}

# Function used to enable a given hook. The next params can be passed
# $1, name of the hook to work with.
# $2, if a previous check must be performed before enabling the hook. By default
#     the hook will be enabled without checking if there's a hook mention in
#     local (via file) or in remote (via folder)
# $3, where to enable the hook, 'local', 'tracked' or both if nothing defined.
enable_hook() {
  local hookName=$1
  local check=0
  if [ $# -gt 1 ]; then
    check=$2
  fi
  local where=('local' 'tracked')
  # TODO: Add a check for invalid values passed
  if [ $# -gt 2 ]; then
    where=($3)
  fi

  for place in "${where[@]}"; do
    case "$place" in
      local)
        # In check, the existence of a file is checked first.
        if [[ $check = 1 && ( ! -f "$GIT_DIR/hooks/$hookName" || -h "$GIT_DIR/hooks/$hookName" ) ]]; then
          continue;
        fi

        # Creates the container directory.
        if [ ! -d "$GIT_DIR/hooks/$hookName.d" ]; then
          rm -f "$GIT_DIR/hooks/$hookName.d"
          mkdir "$GIT_DIR/hooks/$hookName.d"
        fi

        # When appropriate, move the file into the new place
        if [[ -f "$GIT_DIR/hooks/$hookName" && ! -h "$GIT_DIR/hooks/$hookName" ]]; then
          mv "$GIT_DIR/hooks/$hookName" "$GIT_DIR/hooks/$hookName.d/$hookName.00default"
        fi
        ;;

      tracked)
        DESTINATION_NAME="$GIT_DIR/hooks/$TRACKEDHOOKS_FOLDER_NAME"
         # Check there's a place to check for tracked hooks.
        if [ ! -d "$DESTINATION_NAME" ]; then
          continue;
        fi

        # In check, the existence of a container folder is checked first.
        if [[ $check = 1 && ! -d "$DESTINATION_NAME/$hookName.d" ]]; then
          continue;
        fi

        # Creates the container directory.
        if [ ! -d "$DESTINATION_NAME/$hookName.d" ]; then
          rm -f "$DESTINATION_NAME/$hookName.d"
          mkdir "$DESTINATION_NAME/$hookName.d"
        fi
        ;;
    esac

    # Cleans the space and creates the symlink.
    rm -fr "$GIT_DIR/hooks/$hookName"
    ln -sf --relative "$GIT_DIR/hooks/_.sh" "$GIT_DIR/hooks/$hookName"
  done
}

# Function used to disable a given hook. The next params can be passed
# $1, name of the hook to work with.
# $2, if a previous check must be performed before disabling the hook. By default
#     the hook will be disabled without checking if there's a hook mention in
#     local (via file) or in remote (via folder). If check enforced, a search for
#     orphan hooks will be performed to remove them
disable_hook() {
  local hookName=$1
  local check=0
  if [ $# -gt 1 ]; then
    check=$2
  fi

  if [ $check = 0 ]; then
    rm -f "$GIT_DIR/hooks/$hookName"
  else
    if [[ ! -d "$GIT_DIR/hooks/$hookName.d" && ! -d "$GIT_DIR/hooks/$TRACKEDHOOKS_FOLDER_NAME/$hookName.d" ]]; then
      rm -f "$GIT_DIR/hooks/$hookName"
    fi
  fi
}

# Init the git hooks structure.
init() {
  # Creates/recreates the _.sh script
  (_get_trigger_script) > "$GIT_DIR/hooks/_.sh"

  # Makes the new file executable
  chmod +x "$GIT_DIR/hooks/_.sh"

  # Try to create a soft link for trackedhooks/ folder into .git/hooks, if origin exists.
  if [ -d "$TRACKEDHOOKS_DIR" ]; then
    DESTINATION_NAME="$GIT_DIR/hooks/$TRACKEDHOOKS_FOLDER_NAME"

    if [ ! -e "$DESTINATION_NAME" ]; then
      # Destination does not exist.
      ln -sf --relative "$TRACKEDHOOKS_DIR" "$DESTINATION_NAME"
    elif [ ! -h "$DESTINATION_NAME" ]; then
      # Destination is a common file or directory, create backup then link.
      mv "$DESTINATION_NAME" "$DESTINATION_NAME~"
      ln -sf --relative "$TRACKEDHOOKS_DIR" "$DESTINATION_NAME"
    elif [ "`readlink -f $DESTINATION_NAME`" != "$TRACKEDHOOKS_DIR" ]; then
      # Destination is a wrong link, recreates, no backup.
      rm "$DESTINATION_NAME"
      ln -sf --relative "$TRACKEDHOOKS_DIR" "$DESTINATION_NAME"
    fi
  fi
  
  # Enable all hooks that can be checked as existent.
  for hook in $(_git_hooks); do
    enable_hook $hook 1
  done

  # Disable all hooks that existed but no longer does.
  for hook in $(_git_hooks); do
    disable_hook $hook 1
  done

  echo "Init: done!!!";
}

# Helper function used to init the git hooks space after user approval. Used
# in non-init tasks but that require a previous init status
_wanna_init() {
  echo "Git hooks space hasn't been initialized. Do you wish to init it? [Yn]"

  while true; do
    read -pn 1 "Git hooks space hasn't been initialized. Do you wish to init it? [Yn]" yn
      case $yn in
        [Nn])
          echo "NOOOOO"
          break
          ;;
        [Yy])
#        \n)
          echo "YES!!!"
          break
          ;;
#        * ) echo "Please answer yes or no.";;
      esac
  done
}


# Destroy the new git hooks structure in favor of the traditional one.
# TODO: Add a confirmation step for this operation.
destroy() {
  # Loop through all the symlinks that points to the _.sh script.
  for hook in $(_git_hooks); do
    if [[ -h "$GIT_DIR/hooks/$hook" && "`readlink -f $GIT_DIR/hooks/$hook`" = "$GIT_DIR/hooks/_.sh" ]]; then
      # Remove the symlink
      rm -f "$GIT_DIR/hooks/$hook"

      # Restore the .00default script as set inside.
      if [ -e "$GIT_DIR/hooks/$hook.d/$hook.00default" ]; then
        mv "$GIT_DIR/hooks/$hook.d/$hook.00default" "$GIT_DIR/hooks/$hook"
        chmod +x "$GIT_DIR/hooks/$hook"
      fi

      # Remove the container folder.
      rm -rf "$GIT_DIR/hooks/$hook.d"
    fi
  done

  # Work with trackedhooks/ folder.
  DESTINATION_NAME="$GIT_DIR/hooks/$TRACKEDHOOKS_FOLDER_NAME"

  # Remove the symlink that points to trackedhooks/ folder (if it exists).
  if [ -h "$DESTINATION_NAME" ]; then
    rm -f "$DESTINATION_NAME"

    # Check for backup data, to restore them.
    if [ -e "$DESTINATION_NAME~" ]; then
      mv "$DESTINATION_NAME~" "$DESTINATION_NAME"
    fi
  fi

  # Remove the _.sh script
  rm -f "$GIT_DIR/hooks/_.sh"

  echo "Destroy: done!!!";
}

# Add a new git hook entry.
add() {
  echo "add";
_wanna_init
}

# Edit a git hook entry.
edit() {
  echo "edit";
}

# Delete a given git hook entry.
delete() {
  echo "delete";
}

# Call to the main function set
if [ "$MAIN_FUNCTION" != "" ]; then
  $MAIN_FUNCTION
fi
