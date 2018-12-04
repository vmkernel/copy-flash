# TODO: Add a description for the function
# Return values
#   0 – no collision has been detected
#   1 – a collision has been detected, files are different
#   2 - a collision has been detected, but both files are the same
#   -1 – an internal error has occured, can't check for collision
#
# Usage:
#   Check_files_collision <source_directory> <destination_directory> <file_name>
function check_files_collision () {

    SRC_FOLDER_PATH=$1 # Assuming the first parameter as a source folder
    DST_FOLDER_PATH=$2 # Assuming the second parameter as a destination folder
    SRC_FILE_NAME=$3   # Assuming the third parameter as a source file name

    # Checking first parameter
    if [ -z "$SRC_FOLDER_PATH" ]
    then
        echo "*** ERROR *** Insufficient arguments: expected 3, got 0."
        return -1
    fi
    
    # Checking second parameter
    if [ -z "$DST_FOLDER_PATH" ]
    then
        echo "*** ERROR *** Insufficient arguments: expected 3, got 1."
        return -1
    fi

    # Checking third parameter
    if [ -z "$SRC_FILE_NAME" ]
    then
        echo "*** ERROR *** Insufficient arguments: expected 3, got 2."
        return -1
    fi

    # Checking if the source folder exists
    SRC_FOLDER_RECORD=$(ls --all "$SRC_FOLDER_PATH" 2> /dev/null)
    if [ -z "$SRC_FOLDER_RECORD" ]
    then
        echo "*** ERROR **** Source folder doesn't exists. Input argument error."
        return -1
    fi

    # Checking if the destiantion folder exists
    DST_FOLDER_RECORD=$(ls --all "$DST_FOLDER_PATH" 2> /dev/null)
        if [ -z "$DST_FOLDER_PATH" ]
    then
        echo "*** WARNING **** Destination folder doesn't exists. Assuming no collission."
        return 0
    fi
    
    # checking whether a file with the same name exists on the destination
    DST_FILE_RECORD=$(ls --all --full-time "$DST_FOLDER_PATH" 2> /dev/null | grep --ignore-case --max-count 1 "$SRC_FILE_NAME")
    if [ -z "$DST_FILE_RECORD" ] 
    then # file doesn't exists

        echo "Source file '$SRC_FILE_NAME' doesn't exist on the destination. Assuming no collision."
        return 0

    else # file exists

        echo "Destination already has a file with the same name '$SRC_FILE_NAME'."
        SRC_FILE_RECORD=$(ls --all --full-time "$SRC_FOLDER_PATH" 2> /dev/null | grep --ignore-case --max-count 1 "$SRC_FILE_NAME")
        if [ -z "$SRC_FILE_RECORD" ] # something went wrong, can't find source file with the same name
        then 
            echo "*** WARNING *** Unable to get source file information. Assuming collision."
            return 1
        fi

        echo "Raw file records:"
        echo "$SRC_FILE_RECORD (source)"
        echo "$DST_FILE_RECORD (destination)"

        # Comparing files sizes
        DST_FILE_SIZE=$(echo "$DST_FILE_RECORD" | awk '{print $5}')
        SRC_FILE_SIZE=$(echo "$SRC_FILE_RECORD" | awk '{print $5}')
        if [[ -z "$DST_FILE_SIZE" || -z "$SRC_FILE_SIZE" ]]
        then
            echo "*** WARNING *** Unable to get source and/or destination file size. Assuming collision."
            return 1
        fi
        if [ $DST_FILE_SIZE -ne $SRC_FILE_SIZE ]
        then
            echo "A collision has been detected by file size (source = $SRC_FILE_SIZE, destination = $DST_FILE_SIZE)."
            return 1
        #else
        #    echo "Size: $SRC_FILE_SIZE (same)"
        fi

        # Extracting date and time strings for both source and destination files
        DST_FILE_DATE=$(echo "$DST_FILE_RECORD" | awk '{print $6}')
        DST_FILE_TIME_MS=$(echo "$DST_FILE_RECORD" | awk '{print $7}')
        SRC_FILE_DATE=$(echo "$SRC_FILE_RECORD" | awk '{print $6}')
        SRC_FILE_TIME_MS=$(echo "$SRC_FILE_RECORD" | awk '{print $7}')

        # Comparing files years
        DST_FILE_YEAR=$(echo "$DST_FILE_RECORD" | awk '{print $6}' | cut --delimiter='-' --fields=1)
        SRC_FILE_YEAR=$(echo "$SRC_FILE_RECORD" | awk '{print $6}' | cut --delimiter='-' --fields=1)
        if [[ -z "$DST_FILE_YEAR" || -z "$SRC_FILE_YEAR" ]]
        then
            echo "*** WARNING *** Unable to get source and/or destination file year. Assuming collision."
            return 1
        fi
        if [ $DST_FILE_YEAR -ne $SRC_FILE_YEAR ]
        then
            echo "A collision has been detected by file year (source = $SRC_FILE_YEAR, destination = $DST_FILE_YEAR)."
            return 1
        #else
        #    echo "Year: $SRC_FILE_YEAR (same)"
        fi

        # Comparing files month
        DST_FILE_MONTH=$(echo "$DST_FILE_RECORD" | awk '{print $6}' | cut --delimiter='-' --fields=2)
        SRC_FILE_MONTH=$(echo "$SRC_FILE_RECORD" | awk '{print $6}' | cut --delimiter='-' --fields=2)
        if [[ -z "$DST_FILE_MONTH" || -z "$SRC_FILE_MONTH" ]]
        then
            echo "*** WARNING *** Unable to get source and/or destination file month. Assuming collision."
            return 1
        fi
        if [ $DST_FILE_MONTH -ne $SRC_FILE_MONTH ]
        then
            echo "A collision has been detected by file month (source = $SRC_FILE_MONTH, destination = $DST_FILE_MONTH)."
            return 1
        #else
        #    echo "Month: $SRC_FILE_MONTH (same)"
        fi

        # Comparing files day
        DST_FILE_DAY=$(echo "$DST_FILE_RECORD" | awk '{print $6}' | cut --delimiter='-' --fields=3)
        SRC_FILE_DAY=$(echo "$SRC_FILE_RECORD" | awk '{print $6}' | cut --delimiter='-' --fields=3)
        if [[ -z "$DST_FILE_DAY" || -z "$SRC_FILE_DAY" ]]
        then
            echo "*** WARNING *** Unable to get source and/or destination file day. Assuming collision."
            return 1
        fi
        if [ $DST_FILE_DAY -ne $SRC_FILE_DAY ]
        then
            echo "A collision has been detected by file day (source = $SRC_FILE_DAY, destination = $DST_FILE_DAY)."
            return 1
        #else
        #    echo "Day: $SRC_FILE_DAY (same)"
        fi

        # Comparing file hours
        DST_FILE_HOURS=$(echo "$DST_FILE_RECORD" | awk '{print $7}' | cut --delimiter='.' --fields=1 | cut --delimiter=':' --fields='1')
        SRC_FILE_HOURS=$(echo "$SRC_FILE_RECORD" | awk '{print $7}' | cut --delimiter='.' --fields=1 | cut --delimiter=':' --fields='1')
        if [[ -z "$DST_FILE_HOURS" || -z "$SRC_FILE_HOURS" ]]
        then
            echo "*** WARNING *** Unable to get source and/or destination file hours. Assuming collision."
            return 1
        fi
        if [ $DST_FILE_HOURS -ne $SRC_FILE_HOURS ]
        then
            echo "A collision has been detected by file hours (source = $SRC_FILE_HOURS, destination = $DST_FILE_HOURS)."
            return 1
        #else
        #    echo "Hour: $SRC_FILE_HOURS (same)"
        fi

        # Comparing file minutes
        DST_FILE_MINUTES=$(echo "$DST_FILE_RECORD" | awk '{print $7}' | cut --delimiter='.' --fields=1 | cut --delimiter=':' --fields='2')
        SRC_FILE_MINUTES=$(echo "$SRC_FILE_RECORD" | awk '{print $7}' | cut --delimiter='.' --fields=1 | cut --delimiter=':' --fields='2')
        if [[ -z "$DST_FILE_MINUTES" || -z "$SRC_FILE_MINUTES" ]]
        then
            echo "*** WARNING *** Unable to get source and/or destination file minutes. Assuming collision."
            return 1
        fi
        if [ $DST_FILE_MINUTES -ne $SRC_FILE_MINUTES ]
        then
            echo "A collision has been detected by file minutes (source = $SRC_FILE_MINUTES, destination = $DST_FILE_MINUTES)."
            return 1
        #else
        #    echo "Minute: $SRC_FILE_MINUTES (same)"
        fi

        # Comparing file seconds 
        DST_FILE_SECONDS=$(echo "$DST_FILE_RECORD" | awk '{print $7}' | cut --delimiter='.' --fields=1 | cut --delimiter=':' --fields='3')
        SRC_FILE_SECONDS=$(echo "$SRC_FILE_RECORD" | awk '{print $7}' | cut --delimiter='.' --fields=1 | cut --delimiter=':' --fields='3')
        if [[ -z "$DST_FILE_SECONDS" || -z "$SRC_FILE_SECONDS" ]]
        then
            echo "*** WARNING *** Unable to get source and/or destination file seconds. Assuming collision."
            return 1
        fi
        if [ $DST_FILE_SECONDS -ne $SRC_FILE_SECONDS ]
        then
            echo "A collision has been detected by file seconds (source = $SRC_FILE_SECONDS, destination = $DST_FILE_SECONDS)."
            return 1
        #else
        #    echo "Seconds: $SRC_FILE_SECONDS (same)"
        fi

        ## Compating file milliseconds (I don't know for sure should it be here or not)
        #DST_FILE_MILLISECONDS=$(echo "$DST_FILE_RECORD" | awk '{print $7}' | cut --delimiter='.' --fields=2)
        #SRC_FILE_MILLISECONDS=$(echo "$SRC_FILE_RECORD" | awk '{print $7}' | cut --delimiter='.' --fields=2)
        #if [[ -z "$DST_FILE_MILLISECONDS" || -z "$SRC_FILE_MILLISECONDS" ]]
        #then
        #    echo "*** WARNING *** Unable to get source and/or destination file milliseconds. Assuming collision."
        #    return 1
        #fi
        #if [ $DST_FILE_MILLISECONDS -ne $SRC_FILE_MILLISECONDS ]
        #then
        #    echo "A collision has been detected by file milliseconds (source = $SRC_FILE_MILLISECONDS, destination = $DST_FILE_MILLISECONDS)."
        #    return 1
        ##else
        ##    echo "Milliseconds: $SRC_FILE_MILLISECONDS (same)"
        #fi
    fi

    echo "Both files are the same by their's date/time and size."
    return 2
}

# TODO: add a description for the function
# TODO: rename the function
function copy_files () {
    SRC_FOLDER_PATH=$1 # Assuming the first parameter as a source folder
    DST_FOLDER_PATH=$2 # Assuming the second parameter as a destination folder

    # TODO: check settings

    SRC_FILES_LIST=( $(find $SRC_FOLDER_PATH -type f,l) )
    echo "Found ${#SRC_FILES_LIST[*]} file(s)"
    for SRC_FILE_PATH in "${SRC_FILES_LIST[@]}"
    do
        echo ""
        echo "Processing file '$SRC_FILE_PATH'"

        SRC_FILE_NAME=$(basename $SRC_FILE_PATH)
        if [ -z "$SRC_FILE_NAME" ]
        then 
            echo "*** ERROR *** Unable to extract file name from the file path. Will skip this file."
            continue # BUG: Potential loss of data
        fi

        echo "Running collision check..."
        check_files_collision "$SRC_FOLDER_PATH" "$DST_FOLDER_PATH" "$SRC_FILE_NAME"
        EXIT_CODE=$?

        declare -i IS_NEW_NAME_REQUIRED=1
        declare -i IS_SKIP_FILE=0
        case $EXIT_CODE in
            0)
                echo "Will copy the file to its destination with the original name."
                IS_NEW_NAME_REQUIRED=0
            ;;
            2)
                echo "Will skip the file."
                IS_SKIP_FILE=1
            ;;
            1)
                echo "Will copy the file with a new name."
            ;;
            -1)
                echo "An unknown internal error has occured in collisions detection mechanism. Will copy the file with a new name."
            ;;
            *)
                echo "An internal error has occured in collisions detection mechanism: got unsupported exit code ($EXIT_CODE). Will copy the file with a new name."
            ;;
        esac

        if [ $IS_SKIP_FILE -eq 1 ]
        then
            continue
        fi

        if [ $IS_NEW_NAME_REQUIRED -eq 1 ]
        then
            # Extracting base file name and extension from the file name
            declare -i IS_NO_EXTENSION=0
            declare SRC_FILE_BASE_NAME
            SRC_FILE_EXT="${SRC_FILE_NAME##*.}"
            if [ -z "$SRC_FILE_EXT" ]
            then
                echo "*** WARNING *** The file has no extension."
                IS_NO_EXTENSION=1
                SRC_FILE_BASE_NAME=$SRC_FILE_NAME
            else
                SRC_FILE_BASE_NAME="${SRC_FILE_NAME%.*}"
            fi

            if [ -z $SRC_FILE_BASE_NAME ]
            then
                echo "*** ERROR *** Unable to extract base file name from the file name. Will skip the file."
                continue # BUG: Potential loss of data
            fi

            # New file name generation algorithm (e.g.: <original_file_name><N>.<ext>)
            declare DST_FILE_NAME
            declare -i IS_ERROR=0
            declare -i IS_NEW_NAME_FOUND=0
            for FILE_NAME_COUNTER in `seq 1 $FILE_NAME_COUNTER_MAX`;
            do
                # Generating new file name
                DST_FILE_NAME="$SRC_FILE_BASE_NAME($FILE_NAME_COUNTER)"
                if [ $IS_NO_EXTENSION -ne 1 ]
                then
                    DST_FILE_NAME="$DST_FILE_NAME.$SRC_FILE_EXT"
                fi

                # Generating new file full path
                DST_FILE_FULL_PATH="$DST_FOLDER_PATH/$DST_FILE_NAME"
                if [ -z "$DST_FILE_FULL_PATH" ]
                then
                    echo "*** ERROR *** Unable to generate destination file full path. Will skip the file."
                    IS_ERROR=1
                    break # BUG: Potential loss of data
                fi

                # Checking if a file with the same (new) name exists at the destination folder
                DST_FILE_RECORD=$(ls --all $DST_FILE_FULL_PATH 2> /dev/null)
                if [ -z $DST_FILE_RECORD ]
                then # Destination file with the new name is not found, will continue with the name
                    echo "Found first available name: '$DST_FILE_NAME'"
                    IS_NEW_NAME_FOUND=1
                    break
                fi
            done

            if [ $IS_ERROR -ne 0 ]
            then
                continue # BUG: Potential loss of data
            fi

            if [ $IS_NEW_NAME_FOUND -ne 1 ]
            then
                # TODO: Implement some failover mechanism to generata completely random file name
                echo "*** ERROR *** The new file name generation alghorithm has run to it's maximum file counter value ($FILE_NAME_COUNTER_MAX), but was unable to find a free number for the file name. Will skip the file."
                continue
            fi
        fi

        # TODO: rsync call here
        rsync --human-readable --progress --times "$SRC_FILE_PATH" "$DST_FILE_FULL_PATH"

    done
}

SRC_DEVICE_MOUNT_POINT="/home/pi/scripts/rpi-usb-disk-copy" # debug line
DST_FOLDER_FULL_PATH="/opt/usb-disk-copy" # debug line

# Maximum value of file name counter
#TODO: MOVE TO SETTINGS
declare -i FILE_NAME_COUNTER_MAX=1000
if [[ -z "$FILE_NAME_COUNTER_MAX" || $FILE_NAME_COUNTER_MAX -le 0 ]]
then
    echo "*** WARNING *** File name counter maximum is not set. Failing over to default value of 100."
    FILE_NAME_COUNTER_MAX=100
fi
echo "Maximum counter value for file renaming is $FILE_NAME_COUNTER_MAX"
#TODO: MOVE TO SETTINGS

copy_files "$SRC_DEVICE_MOUNT_POINT" "$DST_FOLDER_FULL_PATH"