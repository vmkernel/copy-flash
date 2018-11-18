DST_FOLDER_FULL_PATH='/home/pi'
SRC_FILE_NAME='name-collision-test.dat'
DST_FILE_NAME=$(ls --all --full-time "$DST_FOLDER_FULL_PATH" 2> /dev/null | grep --ignore-case --max-count 1 "$SRC_FILE_NAME") # TODO check if there's multiple lines in the result

# ls --all --full-time /media/hdd/Incoming/
# -rwxrwxrwx 1 root root        59 2018-11-08 10:03:38.919814500 +0000 black-mirror.md5
# -rwxrwxrwx 1 root root        59 2018-11-08 13:06:00.000000000 +0000 mr-robot.md5
# -rwxrwxrwx 1 root root 640349872 2016-08-19 18:25:50.000000000 +0000 name-collision-test.dat

SIZE=$(echo "$DST_FILE_NAME" | awk '{print $5}') # e.g.: 640349872
DATE=$(echo "$DST_FILE_NAME" | awk '{print $6}') # e.g.: 2016-08-19
TIME_WITH_MILLISECONDS=$(echo "$DST_FILE_NAME" | awk '{print $7}') # e.g.: 18:25:50.000000000
TIME=$(echo "$DST_FILE_NAME" | awk '{print $7}' | cut --delimiter='.' --fields=1) # e.g.: 18:25:50
YEAR=$(echo "$DST_FILE_NAME" | awk '{print $6}' | cut --delimiter='-' --fields=1) # e.g.: 2016
MONTH=$(echo "$DST_FILE_NAME" | awk '{print $6}' | cut --delimiter='-' --fields=2) # e.g.: 08
DAY=$(echo "$DST_FILE_NAME" | awk '{print $6}' | cut --delimiter='-' --fields=3) # e.g.: 19
HOURS=$(echo "$DST_FILE_NAME" | awk '{print $7}' | cut --delimiter='.' --fields=1 | cut --delimiter=':' --fields='1') # e.g.: 18
MINUTES=$(echo "$DST_FILE_NAME" | awk '{print $7}' | cut --delimiter='.' --fields=1 | cut --delimiter=':' --fields='2') # e.g.: 25
SECONDS=$(echo "$DST_FILE_NAME" | awk '{print $7}' | cut --delimiter='.' --fields=1 | cut --delimiter=':' --fields='3') # e.g.: 50
MILLISECONDS=$(echo "$DST_FILE_NAME" | awk '{print $7}' | cut --delimiter='.' --fields=2) # e.g.: 000000000