#!/bin/bash

### TODO ###
# * General: find a way to notify user when copy process has started and has finished (Issue #5).
# * rsync: auto rename different files with the same names to avoid skipping (Issue #8).
# * General: use original file creation date as a destination folder name in order to sort data by its real creation date (Issue #9).
# * General: if I'm using 'current' date and time in log file names why I shouldn't use the same name for destination folder, just to match a specific folder with a specific log file (Issue #9).
# * General: fix potential bug. Every time Raspberry Pi stops it saves last known date and time and after the device starts (Issue #9).
#            it restores last known date and time. So the date and time in the device's operations system is incorrect until ntpd updates
#            it from a NTP server. So I need to figure out another name for target folder based on different unique identifier.
# * General: add disk label information (Issue #13).
# * General: check return values (e.g. for mkdir).

#### SETTINGS ####
# Source device mount point (without a trailing slash!)
# Specifies an EMPTY folder in a RPi file system to which a source volume will be mounted
# Examples: /media/usb0, /mnt/source
SRC_DEVICE_MOUNT_POINT='/mnt/usb-disk-copy/source'

# Destination device mount point (without a trailing slash)
# Specifies an EMPTY folder in a RPi file system to which a destination volume will be mounted
# Examples: /media/usb1, /mnt/destination
DST_DEVICE_MOUNT_POINT='/mnt/usb-disk-copy/destination'

# Destination folder relative path
# Specifies the path from destination volume's root folder to a destination folder
# If the parameter is not specified, files or separate folders (depending on IS_ALL_IN_ONE_FOLDER switch) will be placed in the root folder of a destination volume
DST_FOLDER_ROOT='Incoming'

# Separate folder name pattern and operations mode switch
# ALL-IN-ONE folder mode
#   USE WITH CAUTION!
#   If the parameter is NOT set, the script works in ALL-IN-ONE folder mode.
#   Places all files from all source volumes to a single destination directory.
#   No name collision resolution is implemented for now.
#
# SEPARATE folders mode
#   If the parameter IS set, specifies a pattern for a separate folder name that will be created for a source volume EVERY TIME the script starts.
#   Creates a separate folder for each source volume EVERY TIME the script starts.
#   Resuming is NOT supported.
#
#   Example: 
#       usbflash_XXXXXXXXXXXXXXXXXX
#       All the X-es will be replaced by mktmp command to random digits and letters.
DST_FOLDER_NAME_PATTERN=''
#### End of settings section ###


#### FUNCTIONS DEFENITION ####
function check_files_collision () {
    # SUMMARY
    # This function checks collision between two files.
    #
    # DESCRIPTION
    # It receives full path to source and destination files for which collission is checked.
    # If there's no file with the same name in destination folder, the function assumes that there's no collision.
    # If there's a file with the same name in the destination folder, the function compares both files by theirs size and creation date/time.
    # * If any of these attributes are detected to be different, the function assumes that a collision has been detected and we need to work it out.
    # * If all of there attributes are the same, the function assumes that a collision has been detected, but both files are the same and no action is required, so we can skip the file.
    #
    # ARGUMENTS
    #   <source_file> - full path to the source file
    #   <destination_file> - full path to the destination file
    #
    # RETURN CODES
    #   0 – no collision has been detected
    #   1 – a collision has been detected, files are different
    #   2 - a collision has been detected, but both files are the same
    #  -1 – an internal error has occured, can't check for collision
    #
    # USAGE
    #   check_files_collision <source_file> <destination_file>

    local SRC_FILE_PATH=$1 # Assuming the first parameter as a source file path
    local DST_FILE_PATH=$2 # Assuming the second parameter as a destination file path

    # Checking if source file path is set
    if [ -z "$SRC_FILE_PATH" ]
    then
        echo "*** ERROR *** check_files_collision: insufficient arguments (expected 2, got 0)."
        return -1
    fi

    # Checking if destination file path is set
    if [ -z "$DST_FILE_PATH" ]
    then
        echo "*** ERROR *** check_files_collision: insufficient arguments (expected 2, got 1)."
        return -1
    fi
    
    # Checking whether a file with the same name exists on the destination
    local DST_FILE_RECORD=$(ls --all --full-time "$DST_FILE_PATH" 2> /dev/null)
    if [ -z "$DST_FILE_RECORD" ] 
    then # file doesn't exists

        return 0

    else # file exists

        echo "Destination already has a file with the same name."
        local SRC_FILE_RECORD=$(ls --all --full-time "$SRC_FILE_PATH" 2> /dev/null)
        if [ -z "$SRC_FILE_RECORD" ] # something went wrong, can't find source file with the same name
        then 
            echo "*** WARNING *** Unable to get source file information. Assuming collision."
            return 1
        fi

        #echo "Raw file records:"
        echo "$SRC_FILE_RECORD (source)"
        echo "$DST_FILE_RECORD (destination)"

        # Comparing files sizes
        local DST_FILE_SIZE=$(echo "$DST_FILE_RECORD" | awk '{print $5}')
        local SRC_FILE_SIZE=$(echo "$SRC_FILE_RECORD" | awk '{print $5}')
        if [[ -z "$DST_FILE_SIZE" || -z "$SRC_FILE_SIZE" ]]
        then
            echo "*** WARNING *** Unable to get source and/or destination file size. Assuming collision."
            return 1
        fi
        if [ $DST_FILE_SIZE -ne $SRC_FILE_SIZE ]
        then
            echo "A collision has been detected by file size (source = $SRC_FILE_SIZE, destination = $DST_FILE_SIZE)."
            return 1
        fi

        # Comparing files years
        local DST_FILE_YEAR=$(echo "$DST_FILE_RECORD" | awk '{print $6}' | cut --delimiter='-' --fields=1)
        local SRC_FILE_YEAR=$(echo "$SRC_FILE_RECORD" | awk '{print $6}' | cut --delimiter='-' --fields=1)
        if [[ -z "$DST_FILE_YEAR" || -z "$SRC_FILE_YEAR" ]]
        then
            echo "*** WARNING *** Unable to get source and/or destination file year. Assuming collision."
            return 1
        fi
        if [ $DST_FILE_YEAR -ne $SRC_FILE_YEAR ]
        then
            echo "A collision has been detected by file year (source = $SRC_FILE_YEAR, destination = $DST_FILE_YEAR)."
            return 1
        fi

        # Comparing files month
        local DST_FILE_MONTH=$(echo "$DST_FILE_RECORD" | awk '{print $6}' | cut --delimiter='-' --fields=2)
        local SRC_FILE_MONTH=$(echo "$SRC_FILE_RECORD" | awk '{print $6}' | cut --delimiter='-' --fields=2)
        if [[ -z "$DST_FILE_MONTH" || -z "$SRC_FILE_MONTH" ]]
        then
            echo "*** WARNING *** Unable to get source and/or destination file month. Assuming collision."
            return 1
        fi
        if [ $DST_FILE_MONTH -ne $SRC_FILE_MONTH ]
        then
            echo "A collision has been detected by file month (source = $SRC_FILE_MONTH, destination = $DST_FILE_MONTH)."
            return 1
        fi

        # Comparing files day
        local DST_FILE_DAY=$(echo "$DST_FILE_RECORD" | awk '{print $6}' | cut --delimiter='-' --fields=3)
        local SRC_FILE_DAY=$(echo "$SRC_FILE_RECORD" | awk '{print $6}' | cut --delimiter='-' --fields=3)
        if [[ -z "$DST_FILE_DAY" || -z "$SRC_FILE_DAY" ]]
        then
            echo "*** WARNING *** Unable to get source and/or destination file day. Assuming collision."
            return 1
        fi
        if [ $DST_FILE_DAY -ne $SRC_FILE_DAY ]
        then
            echo "A collision has been detected by file day (source = $SRC_FILE_DAY, destination = $DST_FILE_DAY)."
            return 1
        fi

        # Comparing file hours
        local DST_FILE_HOURS=$(echo "$DST_FILE_RECORD" | awk '{print $7}' | cut --delimiter='.' --fields=1 | cut --delimiter=':' --fields='1')
        local SRC_FILE_HOURS=$(echo "$SRC_FILE_RECORD" | awk '{print $7}' | cut --delimiter='.' --fields=1 | cut --delimiter=':' --fields='1')
        if [[ -z "$DST_FILE_HOURS" || -z "$SRC_FILE_HOURS" ]]
        then
            echo "*** WARNING *** Unable to get source and/or destination file hours. Assuming collision."
            return 1
        fi
        if [ $DST_FILE_HOURS -ne $SRC_FILE_HOURS ]
        then
            echo "A collision has been detected by file hours (source = $SRC_FILE_HOURS, destination = $DST_FILE_HOURS)."
            return 1
        fi

        # Comparing file minutes
        local DST_FILE_MINUTES=$(echo "$DST_FILE_RECORD" | awk '{print $7}' | cut --delimiter='.' --fields=1 | cut --delimiter=':' --fields='2')
        local SRC_FILE_MINUTES=$(echo "$SRC_FILE_RECORD" | awk '{print $7}' | cut --delimiter='.' --fields=1 | cut --delimiter=':' --fields='2')
        if [[ -z "$DST_FILE_MINUTES" || -z "$SRC_FILE_MINUTES" ]]
        then
            echo "*** WARNING *** Unable to get source and/or destination file minutes. Assuming collision."
            return 1
        fi
        if [ $DST_FILE_MINUTES -ne $SRC_FILE_MINUTES ]
        then
            echo "A collision has been detected by file minutes (source = $SRC_FILE_MINUTES, destination = $DST_FILE_MINUTES)."
            return 1
        fi

        # Comparing file seconds 
        local DST_FILE_SECONDS=$(echo "$DST_FILE_RECORD" | awk '{print $7}' | cut --delimiter='.' --fields=1 | cut --delimiter=':' --fields='3')
        local SRC_FILE_SECONDS=$(echo "$SRC_FILE_RECORD" | awk '{print $7}' | cut --delimiter='.' --fields=1 | cut --delimiter=':' --fields='3')
        if [[ -z "$DST_FILE_SECONDS" || -z "$SRC_FILE_SECONDS" ]]
        then
            echo "*** WARNING *** Unable to get source and/or destination file seconds. Assuming collision."
            return 1
        fi
        if [ $DST_FILE_SECONDS -ne $SRC_FILE_SECONDS ]
        then
            echo "A collision has been detected by file seconds (source = $SRC_FILE_SECONDS, destination = $DST_FILE_SECONDS)."
            return 1
        fi

        # Compating file milliseconds (I don't know for sure should it be here or not)
        local DST_FILE_MILLISECONDS=$(echo "$DST_FILE_RECORD" | awk '{print $7}' | cut --delimiter='.' --fields=2)
        local SRC_FILE_MILLISECONDS=$(echo "$SRC_FILE_RECORD" | awk '{print $7}' | cut --delimiter='.' --fields=2)
        if [[ -z "$DST_FILE_MILLISECONDS" || -z "$SRC_FILE_MILLISECONDS" ]]
        then
            echo "*** WARNING *** Unable to get source and/or destination file milliseconds. Assuming collision."
            return 1
        fi
        if [ $DST_FILE_MILLISECONDS -ne $SRC_FILE_MILLISECONDS ]
        then
            echo "A collision has been detected by file milliseconds (source = $SRC_FILE_MILLISECONDS, destination = $DST_FILE_MILLISECONDS)."
            return 1
        fi
    fi

    echo "Both files are the same by their date, time and size. Will skip the file."
    return 2
} # check_files_collision

# TODO: Fix potential loss of data, when skipping a file (try mkstemp?)
function copy_folder () {
    # SUMMARY
    # This function discovers and copies all files from a specified folder to a destination folder
    #   implementing extended logic to check if the destination has a file with the same name as the source one.
    #
    # DESCRIPTION
    # If there's no file with the same name on the destination, the function simply copies the source file to the destination.
    # If there's a file with the same name, the function performs some checks to determine should it skip the file (if both are the same)
    #   or make a new name for the file prior calling rsync to copy the file.
    # 
    # ARGUMENTS
    # <source_folder> – full path to the source folder
    # <destination_folder> – full path to the destination folder
    #
    # RETURN CODES
    #   0 – operation has been finished successfully
    #   1 – operation has been finished with errors
    #   2 – operation has been finished with warnings
    #
    # USAGE
    #   copy_folder <source_folder> <destiantion_folder>

    # Assuming the first parameter as a source folder
    local SRC_FOLDER_ROOT_PATH=$1 
    # Assuming the second parameter as a destination folder
    local DST_FOLDER_ROOT_PATH=$2

    # Flag to decide which exit code should return the function upon completion
    local IS_ERRORS_DETECTED=0     
    # Flag to decide which exit code should return the function upon completion
    local IS_WARNINGS_DETECTED=0
    # Maximum value of file name counter
    local FILE_NAME_COUNTER_MAX=1000 

    # Checking source folder path
    if [ -z "$SRC_FOLDER_ROOT_PATH" ]
    then
        echo "*** ERROR *** copy_folder: insufficient arguments (expected 2, got 0)."
        return -1
    fi

    # Checking if the source folder exists
    SRC_FOLDER_RECORD=$(ls --all "$SRC_FOLDER_ROOT_PATH" 2> /dev/null)
    if [ -z "$SRC_FOLDER_RECORD" ]
    then
        echo "*** ERROR **** Source folder doesn't exists. Input argument error."
        return -1
    fi

    # Checking destination folder path
    if [ -z "$DST_FOLDER_ROOT_PATH" ]
    then
        echo "*** ERROR *** copy_folder: insufficient arguments (expected 2, got 1)."
        return -1
    fi

    # Removing trailing slash from destination folder ralative path
    DST_FOLDER_ROOT_PATH=${DST_FOLDER_ROOT_PATH%/}
    if [ -z "$DST_FOLDER_ROOT_PATH" ]
    then
        echo "*** ERROR *** Unable to remove trailing slash from destination folder path."
        return -1
    fi

    # Checking if the destiantion folder exists
    local DST_FOLDER_RECORD=$(ls --all "$DST_FOLDER_ROOT_PATH" 2> /dev/null)
    if [ -z "$DST_FOLDER_RECORD" ]
    then
        echo "*** WARNING **** Destination folder '$DST_FOLDER_ROOT_PATH' doesn't exists. Will create."
        mkdir --parents $DST_FOLDER_ROOT_PATH
        DST_FOLDER_RECORD=$(ls --all "$DST_FOLDER_ROOT_PATH" 2> /dev/null)
        if [ -z "$DST_FOLDER_RECORD" ]
        then
            echo "*** ERROR **** Unable to create the destination folder."
            return -1
        fi
    fi

    # Discoverying files in the source folder
    echo "Searching for files in the source folder..."
    IFS=$'\n' # Setting default delimeter to new-line symbol
    local SRC_FILES_LIST=( $(find $SRC_FOLDER_ROOT_PATH -type f,l) )
    if [ ${#SRC_FILES_LIST[*]} -le 0 ]
    then
        echo "*** WARNING *** No files has been found in the source directory."
        return 1
    else
        echo "Found ${#SRC_FILES_LIST[*]} file(s)"
    fi

    # Removing trailing slashes from source folder root path
    SRC_FOLDER_ROOT_PATH_NO_TRAILING_SLASH=${SRC_FOLDER_ROOT_PATH%/}
    if [ -z $SRC_FOLDER_ROOT_PATH_NO_TRAILING_SLASH ]
    then
        echo "*** WARNING *** Unable to remove trailing slash from source folder root path. Failing back to original path with trailing slash".
    else
        SRC_FOLDER_ROOT_PATH=$SRC_FOLDER_ROOT_PATH_NO_TRAILING_SLASH
    fi

    # Processing each of the discovered files
    for SRC_FILE_PATH in "${SRC_FILES_LIST[@]}"
    do
        # Checking for an empty string
        if [ -z "$SRC_FILE_PATH" ]
        then
            echo "*** ERROR *** Got an empty path from discovered files array instead of a file path. Will skip this line."
            IS_ERRORS_DETECTED=1
            continue # BUG: Potential loss of data (try mkstemp?)
        fi

        echo ""
        echo "Processing file: $SRC_FILE_PATH"

        # Checking if the source file exists
        local SRC_FILE_RECORD=$(ls --all "$SRC_FILE_PATH" 2> /dev/null)
        if [ -z "$SRC_FILE_RECORD" ]
        then
            echo "*** ERROR **** Unable to find the source file '$SRC_FILE_PATH'. Will skip this file."
            IS_ERRORS_DETECTED=1
            continue # BUG: Potential loss of data (try mkstemp?)
        fi

        # Extracting file name from the file path
        local SRC_FILE_NAME=$(basename $SRC_FILE_PATH)
        if [ -z "$SRC_FILE_NAME" ]
        then 
            echo "*** ERROR *** Unable to extract file name from the file path. Will skip this file."
            IS_ERRORS_DETECTED=1
            continue # BUG: Potential loss of data (try mkstemp?)
        fi

        # Extracting relative folder path
        # /media/sdcard0/DCIM/100MEDIA/YI001601.MP4 -> (root folder/)DCIM/100MEDIA(/file.name)
        local FILE_RELATIVE_PATH=${SRC_FILE_PATH#"$SRC_FOLDER_ROOT_PATH"} # Extracting destination file ralative path (without source folder name)
        local FOLDER_RELATIVE_PATH=${FILE_RELATIVE_PATH%"$SRC_FILE_NAME"} # Extracting destination folder ralative path (without source folder and file names)
        FOLDER_RELATIVE_PATH=${FOLDER_RELATIVE_PATH%/} # Removing trailing slash from destination folder ralative path
        FOLDER_RELATIVE_PATH=${FOLDER_RELATIVE_PATH#/} # Removing leading slash from destination folder ralative path

        # Generating source and destination folder full paths
        local SRC_FOLDER_PATH=""
        local DST_FOLDER_PATH=""
        if [ -z "$FOLDER_RELATIVE_PATH" ]
        then
            # Assuming the file in the root folder
            SRC_FOLDER_PATH="$SRC_FOLDER_ROOT_PATH"
            DST_FOLDER_PATH="$DST_FOLDER_ROOT_PATH"
        else
            SRC_FOLDER_PATH="$SRC_FOLDER_ROOT_PATH/$FOLDER_RELATIVE_PATH"
            DST_FOLDER_PATH="$DST_FOLDER_ROOT_PATH/$FOLDER_RELATIVE_PATH"
        fi
        
        # Checking the generated source folder path
        if [ -z $SRC_FOLDER_PATH ]
        then
            echo "*** ERROR *** Unable to generate source folder full path from the source folder root path ($SRC_FOLDER_PATH) and the relative path ($FOLDER_RELATIVE_PATH). Will skip this file."
            IS_ERRORS_DETECTED=1
            continue # BUG: Potential loss of data (try mkstemp?)
        fi
        #echo "Source folder full path: $SRC_FOLDER_PATH"

        # Checking the generated destination folder path
        if [ -z $DST_FOLDER_PATH ]
        then
            echo "*** ERROR *** Unable to generate destianion folder full path from the destination folder root path ($DST_FOLDER_ROOT_PATH) and the relative path ($FOLDER_RELATIVE_PATH). Will skip this file."
            IS_ERRORS_DETECTED=1
            continue # BUG: Potential loss of data (try mkstemp?)
        fi
        #echo "Destination folder full path: $DST_FOLDER_PATH"

        # Making sure that the destination folder exists
        mkdir --parents $DST_FOLDER_PATH
        local DST_FOLDER_FULL_RECORD=$(ls --all "$DST_FOLDER_PATH" 2> /dev/null)
        if [ -z "$DST_FOLDER_FULL_RECORD" ]
        then
            echo "*** ERROR **** Unable to create the destination folder. Will skip this file."
            IS_ERRORS_DETECTED=1
            continue # BUG: Potential loss of data (try mkstemp?)
        fi

        # Generating destinaion file full path
        local DST_FILE_PATH="$DST_FOLDER_PATH/$SRC_FILE_NAME"
        if [ -z "$DST_FILE_PATH" ]
        then
            echo "*** ERROR *** Unable to generate destination file full path. Will skip this file."
            IS_ERRORS_DETECTED=1
            continue # BUG: Potential loss of data (try mkstemp?)
        fi

        # Running collision check
        check_files_collision "$SRC_FILE_PATH" "$DST_FILE_PATH"
        EXIT_CODE=$?

        # Analyzing collision check's result
        local IS_NEW_NAME_REQUIRED=1 # New name is required for the file
        local IS_SKIP_FILE=0         # Both files are the same, will skip safely
        case $EXIT_CODE in
            0)  # No collisions, no file with the same name at the destination
                #echo "No collision has been detected. Will copy the file to its destination with the original name."
                IS_NEW_NAME_REQUIRED=0
            ;;
            2)  # Both files are the same
                #echo "Will skip the file."
                IS_SKIP_FILE=1
            ;;
            1)  # Need a new name for the file, because of a collision
                echo "Will copy the file with a new name."
            ;;
            -1) # Internal error detected, assuming that new name is required
                echo "An unknown internal error has occured in collisions detection mechanism. Will copy the file with a new name."
                IS_WARNINGS_DETECTED=1
            ;;
            *)  # Internal error, unsupported exit code, assuming that new name is required
                echo "An internal error has occured in collisions detection mechanism: got unsupported exit code ($EXIT_CODE). Will copy the file with a new name."
                IS_WARNINGS_DETECTED=1
            ;;
        esac

        # Skipping the file if both files are the same
        if [ $IS_SKIP_FILE -eq 1 ]
        then
            continue
        fi

        if [ $IS_NEW_NAME_REQUIRED -eq 1 ] # Generating a brand new name for the file, if required
        then
            local SRC_FILE_BASE_NAME   # Base name of the source file

            # Extracting base file name and extension from the file name
            local SRC_FILE_EXT="${SRC_FILE_NAME##*.}"
            if [ -z "$SRC_FILE_EXT" ]
            then
                SRC_FILE_BASE_NAME=$SRC_FILE_NAME
            else
                SRC_FILE_BASE_NAME="${SRC_FILE_NAME%.*}"
            fi

            if [ -z $SRC_FILE_BASE_NAME ]
            then
                echo "*** ERROR *** Unable to extract base file name from the file name. Will skip the file."
                IS_ERRORS_DETECTED=1
                continue # BUG: Potential loss of data (try mkstemp?)
            fi

            # New file name generation algorithm (e.g.: <original_file_name><N>.<ext>)
            local DST_FILE_NAME
            local IS_NAME_GEN_ERROR=0
            local IS_NEW_NAME_FOUND=0
            for FILE_NAME_COUNTER in `seq 1 $FILE_NAME_COUNTER_MAX`;
            do
                # Generating new file name
                DST_FILE_NAME="$SRC_FILE_BASE_NAME($FILE_NAME_COUNTER)"
                if [[ ! -z "$SRC_FILE_EXT" ]]
                then
                    DST_FILE_NAME="$DST_FILE_NAME.$SRC_FILE_EXT"
                fi
                if [ -z "$DST_FILE_NAME" ]
                then
                    echo "*** ERROR *** Unable to generate new name for the destination file. Will skip the file."
                    IS_NAME_GEN_ERROR=1
                    break
                fi

                # Generating new file full path
                DST_FILE_PATH="$DST_FOLDER_PATH/$DST_FILE_NAME"
                if [ -z "$DST_FILE_PATH" ]
                then
                    echo "*** ERROR *** Unable to generate destination file full path. Will skip the file."
                    IS_NAME_GEN_ERROR=1
                    break
                fi

                # Checking if a file with the same (new) name exists at the destination folder
                echo "Checking destination file name '$DST_FILE_NAME'..."
                check_files_collision "$SRC_FILE_PATH" "$DST_FILE_PATH"
                EXIT_CODE=$?

                case $EXIT_CODE in
                    0) # No file with the same name in the destination folder
                        echo "Found first available name for the file."
                        IS_NEW_NAME_FOUND=1
                        break
                    ;;
                    1)  # Need a new name for the file, because of a collision
                        #echo "The files are not the same. Will search further for the first available name."
                        continue
                    ;;
                    2)  # Both files are the same
                        echo "Both files are the same. Will skip the file."
                        IS_SKIP_FILE=1
                        break
                    ;;
                    *)  # Internal error, unsupported exit code, assuming that new name is required
                        echo "An internal error has occured in collisions detection mechanism: got unsupported exit code ($EXIT_CODE). Will copy the file with a new name."
                        IS_WARNINGS_DETECTED=1
                    ;;
                esac
            done

            # Skipping the file if both files are the same
            if [ $IS_SKIP_FILE -eq 1 ]
            then
                continue
            fi

            if [ $IS_NAME_GEN_ERROR -ne 0 ]
            then
                IS_ERRORS_DETECTED=1
                continue # BUG: Potential loss of data (try mkstemp?)
            fi

            if [ $IS_NEW_NAME_FOUND -ne 1 ]
            then
                echo "*** ERROR *** The new file name generation alghorithm has run to it's maximum file counter value ($FILE_NAME_COUNTER_MAX), but was unable to find a free number for the file name. Will skip the file."
                IS_ERRORS_DETECTED=1
                continue # BUG: Potential loss of data (try mkstemp?)
            fi
        else
            DST_FILE_PATH="$DST_FOLDER_PATH/$SRC_FILE_NAME"
            if [ -z "$DST_FILE_PATH" ]
            then
                echo "*** ERROR *** Unable to generate destination file full path. Will skip the file."
                IS_ERRORS_DETECTED=1
                continue # BUG: Potential loss of data (try mkstemp?)
            fi
        fi

        # Calling rsync to copy the file
        echo "Destination: $DST_FILE_PATH"
        rsync --human-readable --progress --times "$SRC_FILE_PATH" "$DST_FILE_PATH"
        EXIT_CODE=$?
        if [ $EXIT_CODE -ne 0 ]
        then
            echo "*** ERROR *** rsync has failed to copy the file ($EXIT_CODE)"
            IS_ERRORS_DETECTED=1
        else
            echo "rsync has finished successfylly ($EXIT_CODE)"
        fi
    done

    # Exiting with the corresponding exti code
    if [ $IS_ERRORS_DETECTED -eq 1 ]
    then
        return 1 # some errors has been detected
    fi

    if [ $IS_WARNINGS_DETECTED -eq 1 ]
    then
        return 2 # some warnings has been detected
    fi

    return 0 # no issues has been detected
} # copy_folder
#### End of functions definition ####


### MAIN SECTION ###
SCRIPT_NAME=`basename "$0"`
echo ""
echo "THE SCRIPT HAS STARTED ($SCRIPT_NAME)"
echo "CHECKING SETTING..."
echo "Source device mount point: $SRC_DEVICE_MOUNT_POINT"
echo "Destination device mount moint: $DST_DEVICE_MOUNT_POINT"
echo "Destination folder relative path: $DST_FOLDER_ROOT"
echo "Destination folder name pattern: $DST_FOLDER_NAME_PATTERN"

#### Checking settings ####
# Checking if destination device mount point / source folder is set
if [ -z "$DST_DEVICE_MOUNT_POINT" ]
then
    echo "*** ERROR *** Destination mount point is not set. Check settings! The script has terminated unexpectedly."
    exit 1
else
    # Removing trailing slashes if any
    DST_DEVICE_MOUNT_POINT=${DST_DEVICE_MOUNT_POINT%/}
    if [ -z "$DST_DEVICE_MOUNT_POINT" ]
    then
        echo "*** ERROR *** Failed to remove trailing slash from destination mount point path. The script has terminated unexpectedly."
        exit 1
    fi

    mkdir --parents $DST_DEVICE_MOUNT_POINT
    # TODO: check return values
fi # Checking if destination device mount point / source folder is set

# Checking if source device mount point / source folder is set
if [ -z "$SRC_DEVICE_MOUNT_POINT" ] 
then
    echo "*** ERROR *** Source mount point is not set. Check settings! The script has terminated unexpectedly."
    exit 1
else
    # Removing trailing slashes if any
    SRC_DEVICE_MOUNT_POINT=${SRC_DEVICE_MOUNT_POINT%/}
    if [ -z "$SRC_DEVICE_MOUNT_POINT" ]
    then
        echo "*** ERROR *** Failed to remove trailing slash from source mount point path. The script has terminated unexpectedly."
        exit 1
    fi

    mkdir --parents $SRC_DEVICE_MOUNT_POINT
    # TODO: check return values
fi # Checking if source device mount point / source folder is set

# Checking if destination folder relative path is set
if [ -z "$DST_FOLDER_ROOT" ]
then
    echo "*** WARNING *** Destination folder is not set. Assuming root folder."
fi

# Checking operations mode switch / separate destination folder name pattern
IS_ALL_IN_ONE_FOLDER=1 # Operations mode switch, by default assuming all-in-one directory mode
if [ -z "$DST_FOLDER_NAME_PATTERN" ]
then
    echo "Operations mode: all-in-one folder (unique folder name pattern is NOT set)."
else
    IS_ALL_IN_ONE_FOLDER=0
    echo "Operations mode: separate folder (unique folder name pattern is set)."
fi # Checking operations mode switch / separate destination folder name pattern
#### End of checking settings ####


#### Checking arguments
echo ""
echo "CHECKING ARGUMENTS..."

# Checking if specific device to bind to set using an argument
IS_BIND_TO_DEVICE=0 # no device binding by default
if [ -z "$1" ]
then
    # No arguments has been specified
    echo "No device name is specified in the command line for the script. Will do a full scan."
else
    # Got at least one argument
    echo "Got the device name from the command line: $1"

    # Checking if the device specified by the argument is present in the system
    IS_DEVICE_PRESENT=$(ls -la /dev/ | grep --max-count 1 --ignore-case $1)
    if [ -z "$IS_DEVICE_PRESENT" ]
    then
        echo "*** WARNING **** Unable to find the device from the command line '/dev/$1'. Will do a full scan."
    else
        echo "The specified device '/dev/$1' is attached to the system. Will try to bind to it."
        IS_BIND_TO_DEVICE=1
    fi # Checking if the device specified by the argument is present in the system
fi # Checking if specific device to bind to set using an argument
#### End of checking arguments


#### Devices discovery ####
echo ""
echo "SEARCHING FOR DEVICES..."

# Enumerating all attached SCSI disks using name pattern /dev/sd*1
ATTACHED_SCSI_DISKS=( $(ls -la /dev/ | grep --ignore-case --perl-regexp "sd(\w+)1" | awk '{print $10}' | sort) )
if [ ${#ATTACHED_SCSI_DISKS[*]} -le 0 ]
then
    # Got an empty array, assuming no device was found
    echo "*** WARNING *** No devices found. The script has terminated prematurely."
    exit 0
else
    echo "Found ${#ATTACHED_SCSI_DISKS[*]} device(s): ${ATTACHED_SCSI_DISKS[*]}"
fi # Enumerating all attached SCSI disks using name pattern /dev/sd*1

# Checking attached SCSI disks count
if [ ${#ATTACHED_SCSI_DISKS[*]} -lt 2 ] 
then
    # Exit if there's less than two disks attached.
    echo "*** WARNING *** Not enough devices. Need at least two devices to start a copying process. The script has terminated prematurely."
    exit 0
else 
    # Two (2) or more disks has been attached
    DST_DEVICE_NAME=""
    SRC_DEVICE_NAME=""
    if [ $IS_BIND_TO_DEVICE -eq 1 ] # Specific device binding
    then
        # Trying to bind to the specified device
        if [ "${ATTACHED_SCSI_DISKS[0]}" = "$1" ] # Comparing the attached device with the first device found in system
        then
            # If it's a match, then do nothing, assuming this is the destination device and it's just attached
            echo "*** WARNING *** Auto-detect is assuming the devices as the first device in the system and will use it as a destination device as soon as a source device appears. Waiting for a source device. The script has terminated prematurely."
            exit 0
        else 
            # If it's NOT a match, assuming the first device as the destination device and the current device as a source.
            DST_DEVICE_NAME=${ATTACHED_SCSI_DISKS[0]}
            SRC_DEVICE_NAME=$1
            echo "Destination device name (auto-detection): $DST_DEVICE_NAME"
            echo "Source device name (auto-detection): $SRC_DEVICE_NAME"
        fi # Comparing the attached device with the first device found in system
    else 
        # Performing sequential detection
        DST_DEVICE_NAME=${ATTACHED_SCSI_DISKS[0]}
        SRC_DEVICE_NAME=${ATTACHED_SCSI_DISKS[1]}
        echo "Destination device name (sequential detection): $DST_DEVICE_NAME"
        echo "Source device name (sequential detection): $SRC_DEVICE_NAME"
    fi # Specific device binding

    # Checking if the destination device name is set correctly
    if [ -z "$DST_DEVICE_NAME" ]
    then
        echo "*** ERROR *** Unable to get destination device name. The script has terminated unexpectedly."
        exit 1
    fi

    # Checking if the source device name is set correctly
    if [ -z "$SRC_DEVICE_NAME" ]
    then
        echo "*** ERROR *** Unable to get source device name. The script has terminated unexpectedly."
        exit 1
    fi

    # Getting the destination device id
    DST_DEVICE_ID=$(ls -la /dev/disk/by-id/ | grep --max-count 1 --ignore-case $DST_DEVICE_NAME | awk '{print $9}')
    if [ -z "$DST_DEVICE_ID" ]
    then
        echo "*** WARNING *** Unable to find destination device ID."
    else
        echo "Destination device id: $DST_DEVICE_ID"
    fi

    # Getting the source device id
    SRC_DEVICE_ID=$(ls -la /dev/disk/by-id/ | grep --max-count 1 --ignore-case $SRC_DEVICE_NAME | awk '{print $9}')
    if [ -z "$SRC_DEVICE_ID" ]
    then
        echo "*** WARNING *** Unable to find source device ID."
    else
        echo "Source device id: $SRC_DEVICE_ID"
    fi
fi # Checking attached SCSI disks count
#### End of devices discovery ####


#### Checking if the mount points are free ####
echo ""
echo "CHECKING MOUNT POINTS AND DEVICES..."

## SOURCE
# Unmounting the source MOUNT POINT if it's already mounted
MOUNT_STATUS=$(cat /proc/mounts | grep --max-count 1 --ignore-case $SRC_DEVICE_MOUNT_POINT)
if [ -z "$MOUNT_STATUS" ] # Is the source mountpoint already mounted
then
    echo "Source mount point '$SRC_DEVICE_MOUNT_POINT' is not mounted."
else
    # Unmounting already mounted mountpoint
    echo "Source mount point '$SRC_DEVICE_MOUNT_POINT' is already mounted, unmounting..."
    umount $SRC_DEVICE_MOUNT_POINT

    # Checking if source mountpoint has been unmounted
    MOUNT_STATUS=$(cat /proc/mounts | grep --max-count 1 --ignore-case $SRC_DEVICE_MOUNT_POINT)
    if [ -z "$MOUNT_STATUS" ]
    then
        echo "Source mount point has been unmounted successfully."
    else
        echo "*** ERROR *** Unable to unmount source mount point. The script has terminated unexpectedly."
        exit 1
    fi
fi # Is the source mountpoint already mounted

# Unmounting the source DEVICE if it's already mounted
MOUNT_STATUS=$(cat /proc/mounts | grep --max-count 1 --ignore-case $SRC_DEVICE_NAME)
if [ -z "$MOUNT_STATUS" ] # Is the source device already mounted
then
    echo "Source device '/dev/$SRC_DEVICE_NAME' is not mounted."
else
    echo "Source device '/dev/$SRC_DEVICE_NAME' is already mounted, unmounting..."
    umount /dev/$SRC_DEVICE_NAME

    # Checking if source device has been unmounted
    MOUNT_STATUS=$(cat /proc/mounts | grep --max-count 1 --ignore-case $SRC_DEVICE_NAME)
    if [ -z "$MOUNT_STATUS" ]
    then
        echo "Source device has been unmounted successfully."
    else
        echo "*** ERROR *** Unable to unmount source device. The script has terminated unexpectedly."
        exit 1
    fi
fi # Is the source device already mounted

# DESTINATION
# Unmounting the source MOUNT POINT if it's already mounted
MOUNT_STATUS=$(cat /proc/mounts | grep --max-count 1 --ignore-case $DST_DEVICE_MOUNT_POINT)
if [ -z "$MOUNT_STATUS" ] # Is the destination mountpoint already mounted
then
    echo "Destination mount point '$DST_DEVICE_MOUNT_POINT' is not mounted."
else
    echo "Destination mount point '$DST_DEVICE_MOUNT_POINT' is already mounted, unmounting..."
    umount $DST_DEVICE_MOUNT_POINT

    # Checking if destination mountpoint has been unmounted
    MOUNT_STATUS=$(cat /proc/mounts | grep --max-count 1 --ignore-case $DST_DEVICE_MOUNT_POINT)
    if [ -z "$MOUNT_STATUS" ]
    then
        echo "Destination mount point has been unmounted successfully."
    else
        echo "*** ERROR *** Unable to unmount destination mount point. The script has terminated unexpectedly."
        exit 1
    fi
fi # Is the destination mountpoint already mounted

# Unmounting the source DEVICE if it's already mounted
MOUNT_STATUS=$(cat /proc/mounts | grep --max-count 1 --ignore-case $DST_DEVICE_NAME)
if [ -z "$MOUNT_STATUS" ] # Is the destination device already mounted
then
    echo "Destination device '/dev/$DST_DEVICE_NAME' is not mounted."
else
    echo "Destination device '/dev/$DST_DEVICE_NAME' is already mounted, unmounting..."
    umount /dev/$DST_DEVICE_NAME

    # Checking if destination device has been unmounted
    MOUNT_STATUS=$(cat /proc/mounts | grep --max-count 1 --ignore-case $DST_DEVICE_NAME)
    if [ -z "$MOUNT_STATUS" ]
    then
        echo "Destination device has been unmounted successfully ."
    else
        echo "*** ERROR *** Unable to unmount destination device. The script has terminated unexpectedly."
        exit 1
    fi
fi # Is the destination device already mounted
#### End of checking if the mount points are free ####


#### Mounting devices ####
# Mounting the devices to the mount points
echo ""
echo "MOUNTING DEVICES..."
echo "Mounting source device '$SRC_DEVICE_NAME' to mount point '$SRC_DEVICE_MOUNT_POINT'..."

mount /dev/$SRC_DEVICE_NAME $SRC_DEVICE_MOUNT_POINT
MOUNT_STATUS=$(cat /proc/mounts | grep --max-count 1 --ignore-case $SRC_DEVICE_MOUNT_POINT)
if [ -z "$MOUNT_STATUS" ] # Is the source device mountpoint mounted
then
    echo "*** ERROR *** Unable to mount source device. The script has terminated unexpectedly."
    exit 1
else
    echo "Source device has been mounted successfully."
fi # Is the source device mountpoint has been mounted

echo "Mounting destination device '$DST_DEVICE_NAME' to mount point '$DST_DEVICE_MOUNT_POINT'..."
mount /dev/$DST_DEVICE_NAME $DST_DEVICE_MOUNT_POINT
MOUNT_STATUS=$(cat /proc/mounts | grep --max-count 1 --ignore-case $DST_DEVICE_MOUNT_POINT)
if [ -z "$MOUNT_STATUS" ] # Is the destination device mountpoint mounted
then
    echo "*** ERROR *** Unable to mount destination device. The script has terminated unexpectedly."
    exit 1
else
    echo "Destination device has been mounted successfully."
fi # Checking if destination device mountpoint has been mounted
#### End of mounting devices ####


#### Generating destination folder path ####
echo ""
echo "PREPARING DESTINATION FOLDER..."
if [ -z "$DST_FOLDER_ROOT" ] # Is destination folder set
then
    DST_FOLDER_FULL_PATH="$DST_DEVICE_MOUNT_POINT"
else
    DST_FOLDER_FULL_PATH="$DST_DEVICE_MOUNT_POINT/$DST_FOLDER_ROOT"
fi # Is destination folder set

if [ -z "$DST_FOLDER_FULL_PATH" ] # Is destination folder full path generated
then
    echo "*** ERROR *** Unable to generate destination folder root path. The script has terminated unexpectedly."
    exit 1
else
    echo "Destination folder root path: $DST_FOLDER_FULL_PATH"
fi # Is destination folder full path generated


# Checking if destination folder name pattern is specified
if [[ ! -z "$DST_FOLDER_NAME_PATTERN" ]]
then
    # Old-way, separate folder mode
    echo "Generating temporary folder..."
    DST_FOLDER_FULL_PATH_FAILOVER="$DST_FOLDER_FULL_PATH"
    DST_FOLDER_FULL_PATH="$(mktemp --directory $DST_FOLDER_FULL_PATH/$DST_FOLDER_NAME_PATTERN)"
    if [ -z "$DST_FOLDER_FULL_PATH" ] # Is the destination folder full path set
    then
        echo "*** WARNING *** Unable to generate unique destination folder path. Will fail-over to all-in-one mode."
        IS_ALL_IN_ONE_FOLDER=1
        DST_FOLDER_FULL_PATH="$DST_FOLDER_FULL_PATH_FAILOVER"
        if [ -z "$DST_FOLDER_FULL_PATH" ]
        then
            echo "*** ERROR *** Unable to use failover path. The script has terminated unexpectedly."
            exit 1
        fi
    fi # Is the destination folder full path set
fi # Checking if destination folder name pattern is specified
#### End of generating destination folder path ####


#### Copying files ####
echo ""
echo "COPYING FILES..."
echo "Source: $SRC_DEVICE_MOUNT_POINT (/dev/$SRC_DEVICE_NAME)"
echo "Destination: '$DST_FOLDER_FULL_PATH' (/dev/$DST_DEVICE_NAME)"

if [ $IS_ALL_IN_ONE_FOLDER -eq 0 ] # Operations mode mode selection
then
    # Old-way, separate folder mode
    # Trailing slashes is added to skip parent directory creation on destination
    echo "Offloading all the work to rsync for the old-way copy mode..."
    rsync --recursive --human-readable --progress --times "$SRC_DEVICE_MOUNT_POINT/" $DST_FOLDER_FULL_PATH

else # New-way, all-in-one folder mode
    copy_folder $SRC_DEVICE_MOUNT_POINT $DST_FOLDER_FULL_PATH
    
fi # Operations mode mode selection

EXIT_CODE=$?
echo "Copy process has finished with code: $EXIT_CODE"
#### End of copying files ####


#### Cleaning up ####
echo ""
echo "UNMOUNTING DEVICES..."
# Unmounting the destination devices from the mount point
umount -f $DST_DEVICE_MOUNT_POINT
MOUNT_STATUS=$(cat /proc/mounts | grep --max-count 1 --ignore-case $DST_DEVICE_MOUNT_POINT)
if [ -z "$MOUNT_STATUS" ]
then
    echo "The mount point '$DST_DEVICE_MOUNT_POINT' has been unmounted successfully."
else
    echo "*** ERROR *** Unable to unmount mount point '$DST_DEVICE_MOUNT_POINT'."
fi

# Unmounting the source devices from the mount point
umount $SRC_DEVICE_MOUNT_POINT
MOUNT_STATUS=$(cat /proc/mounts | grep --max-count 1 --ignore-case $SRC_DEVICE_MOUNT_POINT)
if [ -z "$MOUNT_STATUS" ]
then
    echo "The mount point '$SRC_DEVICE_MOUNT_POINT' has been unmounted successfully."
else
    echo "*** ERROR *** Unable to unmount mount point '$SRC_DEVICE_MOUNT_POINT'."
fi
#### End of cleaning up ####

echo ""
echo "THE SCRIPT HAS RUN TO ITS END ($SCRIPT_NAME)"

exit $EXIT_CODE