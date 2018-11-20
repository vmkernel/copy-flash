# Returns 0 if there's no collision and 1 if there is.
# Example: check_files_collision <source_directory> <destination_directory> <file_name>
function check_files_collision () {

    SRC_FOLDER_PATH=$1
    DST_FOLDER_PATH=$2
    SRC_FILE_NAME=$3

    # checking whether a file with the same name exists on the destination
    DST_FILE_RECORD=$(ls --all --full-time "$DST_FOLDER_PATH" 2> /dev/null | grep --ignore-case --max-count 1 "$SRC_FILE_NAME")
    if [ -z "$DST_FILE_RECORD" ] 
    then # file doesn't exists

        echo "Source file '$SRC_FILE_NAME' doesn't exist on the destination."
        return 0

    else # file exists

        echo "Destination already has a file with the same name '$SRC_FILE_NAME'."
        SRC_FILE_RECORD=$(ls --all --full-time "$SRC_FOLDER_PATH" 2> /dev/null | grep --ignore-case --max-count 1 "$SRC_FILE_NAME")
        if [ -z "$SRC_FILE_RECORD" ] # something went wrong, can't find source file with the same name
        then 
            echo "*** WARNING *** Unable to get source file information. Assuming collision. Will rename source file during copying process."
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
            echo "*** WARNING *** Unable to get source and/or destination file size. Assuming collision. Will rename source file during copying process."
            return 1
        fi
        if [ $DST_FILE_SIZE -ne $SRC_FILE_SIZE ]
        then
            echo "Collision detected by file size: source = $SRC_FILE_SIZE, destination = $DST_FILE_SIZE."
            #return 1
        else
            echo "Size: $SRC_FILE_SIZE (same)"
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
            echo "*** WARNING *** Unable to get source and/or destination file year. Assuming collision. Will rename source file during copying process."
            return 1
        fi
        if [ $DST_FILE_YEAR -ne $SRC_FILE_YEAR ]
        then
            echo "Collision detected by file year: source = $SRC_FILE_YEAR, destination = $DST_FILE_YEAR."
            #return 1
        else
            echo "Year: $SRC_FILE_YEAR (same)"
        fi

        # Comparing files month
        DST_FILE_MONTH=$(echo "$DST_FILE_RECORD" | awk '{print $6}' | cut --delimiter='-' --fields=2)
        SRC_FILE_MONTH=$(echo "$SRC_FILE_RECORD" | awk '{print $6}' | cut --delimiter='-' --fields=2)
        if [[ -z "$DST_FILE_MONTH" || -z "$SRC_FILE_MONTH" ]]
        then
            echo "*** WARNING *** Unable to get source and/or destination file month. Assuming collision. Will rename source file during copying process."
            return 1
        fi
        if [ $DST_FILE_MONTH -ne $SRC_FILE_MONTH ]
        then
            echo "Collision detected by file month: source = $SRC_FILE_MONTH, destination = $DST_FILE_MONTH."
            #return 1
        else
            echo "Month: $SRC_FILE_MONTH (same)"
        fi

        # Comparing files day
        DST_FILE_DAY=$(echo "$DST_FILE_RECORD" | awk '{print $6}' | cut --delimiter='-' --fields=3)
        SRC_FILE_DAY=$(echo "$SRC_FILE_RECORD" | awk '{print $6}' | cut --delimiter='-' --fields=3)
        if [[ -z "$DST_FILE_DAY" || -z "$SRC_FILE_DAY" ]]
        then
            echo "*** WARNING *** Unable to get source and/or destination file day. Assuming collision. Will rename source file during copying process."
            return 1
        fi
        if [ $DST_FILE_DAY -ne $SRC_FILE_DAY ]
        then
            echo "Collision detected by file day: source = $SRC_FILE_DAY, destination = $DST_FILE_DAY."
            #return 1
        else
            echo "Day: $SRC_FILE_DAY (same)"
        fi

        # Comparing file hours
        DST_FILE_HOURS=$(echo "$DST_FILE_RECORD" | awk '{print $7}' | cut --delimiter='.' --fields=1 | cut --delimiter=':' --fields='1')
        SRC_FILE_HOURS=$(echo "$SRC_FILE_RECORD" | awk '{print $7}' | cut --delimiter='.' --fields=1 | cut --delimiter=':' --fields='1')
        if [[ -z "$DST_FILE_HOURS" || -z "$SRC_FILE_HOURS" ]]
        then
            echo "*** WARNING *** Unable to get source and/or destination file hours. Assuming collision. Will rename source file during copying process."
            return 1
        fi
        if [ $DST_FILE_HOURS -ne $SRC_FILE_HOURS ]
        then
            echo "Collision detected by file hours: source = $SRC_FILE_HOURS, destination = $DST_FILE_HOURS."
            #return 1
        else
            echo "Hour: $SRC_FILE_HOURS (same)"
        fi

        # Comparing file minutes
        DST_FILE_MINUTES=$(echo "$DST_FILE_RECORD" | awk '{print $7}' | cut --delimiter='.' --fields=1 | cut --delimiter=':' --fields='2')
        SRC_FILE_MINUTES=$(echo "$SRC_FILE_RECORD" | awk '{print $7}' | cut --delimiter='.' --fields=1 | cut --delimiter=':' --fields='2')
        if [[ -z "$DST_FILE_MINUTES" || -z "$SRC_FILE_MINUTES" ]]
        then
            echo "*** WARNING *** Unable to get source and/or destination file minutes. Assuming collision. Will rename source file during copying process."
            return 1
        fi
        if [ $DST_FILE_MINUTES -ne $SRC_FILE_MINUTES ]
        then
            echo "Collision detected by file minutes: source = $SRC_FILE_MINUTES, destination = $DST_FILE_MINUTES."
            #return 1
        else
            echo "Minute: $SRC_FILE_MINUTES (same)"
        fi

        # Comparing file seconds 
        DST_FILE_SECONDS=$(echo "$DST_FILE_RECORD" | awk '{print $7}' | cut --delimiter='.' --fields=1 | cut --delimiter=':' --fields='3')
        SRC_FILE_SECONDS=$(echo "$SRC_FILE_RECORD" | awk '{print $7}' | cut --delimiter='.' --fields=1 | cut --delimiter=':' --fields='3')
        if [[ -z "$DST_FILE_SECONDS" || -z "$SRC_FILE_SECONDS" ]]
        then
            echo "*** WARNING *** Unable to get source and/or destination file seconds. Assuming collision. Will rename source file during copying process."
            return 1
        fi
        if [ $DST_FILE_SECONDS -ne $SRC_FILE_SECONDS ]
        then
            echo "Collision detected by file seconds: source = $SRC_FILE_SECONDS, destination = $DST_FILE_SECONDS."
            #return 1
        else
            echo "Seconds: $SRC_FILE_SECONDS (same)"
        fi

        ## Compating file milliseconds (I don't know for sure should it be here or not)
        #DST_FILE_MILLISECONDS=$(echo "$DST_FILE_RECORD" | awk '{print $7}' | cut --delimiter='.' --fields=2)
        #SRC_FILE_MILLISECONDS=$(echo "$SRC_FILE_RECORD" | awk '{print $7}' | cut --delimiter='.' --fields=2)
        #if [[ -z "$DST_FILE_MILLISECONDS" || -z "$SRC_FILE_MILLISECONDS" ]]
        #then
        #    echo "*** WARNING *** Unable to get source and/or destination file milliseconds. Assuming collision. Will rename source file during copying process."
        #    return 1
        #fi
        #if [ $DST_FILE_MILLISECONDS -ne $SRC_FILE_MILLISECONDS ]
        #then
        #    echo "Collision detected by file milliseconds: source = $SRC_FILE_MILLISECONDS, destination = $DST_FILE_MILLISECONDS."
        #    #return 1
        #else
        #    echo "Milliseconds: $SRC_FILE_MILLISECONDS (same)"
        #fi
    fi

    # No colissions has been detected
    return 0
}


check_files_collision /media/flash/ /media/hdd/Incoming/ name-collision-test.dat