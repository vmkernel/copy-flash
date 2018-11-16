ls --all --full-time /media/hdd/Incoming/
# -rwxrwxrwx 1 root root        59 2018-11-08 10:03:38.919814500 +0000 black-mirror.md5
# -rwxrwxrwx 1 root root        59 2018-11-08 13:06:00.000000000 +0000 mr-robot.md5
# -rwxrwxrwx 1 root root 640349872 2016-08-19 18:25:50.000000000 +0000 name-collision-test.dat


ls -la /media/hdd/Incoming/
# -rwxrwxrwx 1 root root        59 Nov  8 10:03 black-mirror.md5
# -rwxrwxrwx 1 root root        59 Nov  8 13:06 mr-robot.md5
# -rwxrwxrwx 1 root root 640349872 Aug 19  2016 name-collision-test.dat
DAY=$(ls -la /media/hdd/Incoming/ | grep --ignore-case --max-count 1 collision | awk '{print $7}')
MONTH=$(ls -la /media/hdd/Incoming/ | grep --ignore-case --max-count 1 collision | awk '{print $6}')
YEAR=$(ls -la /media/hdd/Incoming/ | grep --ignore-case --max-count 1 collision | awk '{print $8}')
SIZE=$(ls -la /media/hdd/Incoming/ | grep --ignore-case --max-count 1 collision | awk '{print $5}')