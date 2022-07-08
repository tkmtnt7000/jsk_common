#!/bin/bash

usage() { echo "Usage: $0 [-p rosbag file directory ] [-b base scan topic ] [-d output directory]" 1>&2; exit 1; }

function make_map()
{

    rosparam set use_sim_time true
    FILENAME=$(basename "$file" .bag)
    # TOPIC_LIST=$(rostopic list)
    # for topic in ${TOPIC_LIST}; do
    #     TOPIC_INFO=$(rostopic info ${topic} | grep "Type")
    #     if [[ ${TOPIC_INFO} == "Type: sensor_msgs/LaserScan" ]]; then
    #         BASE_SCAN_TOPIC=${topic}
    #     fi
    # done
    echo ${BASE_SCAN_TOPIC}
    echo ${file}
    rosrun gmapping slam_gmapping scan:=${BASE_SCAN_TOPIC} map:=map_diff _odom_frame:=/map _map_frame:=/dummy_map &
    echo "=========gmapping"
    sleep 3
    echo ${file}
    rosbag play --clock $file &&
        ROSBAG_PLAY_RESULT=$?
    echo "=================rosbag"

    if [ $ROSBAG_PLAY_RESULT -ne 0 ]; then
        echo "Failed to play rosbag appropriately"
    fi

    sleep 1

    ### Set output directory
    # if [ -n "${OUTPUT_DIR}" ]; then
    #     echo "cd ${OUTPUT_DIR}"
    #     $(cd "$(pwd)/${OUTPUT_DIR}") &&
    #         echo $(pwd)
    # fi
    # echo "====="
    # echo $(pwd)
    # echo "====="

    rosrun map_server map_saver map:=map_diff -f ${FILENAME} || exit 1
    echo "Done"
    sleep 1

    rosnode kill /slam_gmapping
    sleep 1
}

# FILEPATH="/home/tsukamoto/rosbag/kitchen-demo/*"
# FILEPATH="${1}/*"
# BASE_SCAN_TOPIC=$2
FILEPATH=""
BASE_SCAN_TOPIC="/base_scan/throttled"
OUTPUT_DIR=""

while getopts "p:b:o:" OPT; do
    case "${OPT}" in
        p)
            FILEPATH="${OPTARG}"
            ;;
        b)
            BASE_SCAN_TOPIC="{OPTARG}"
            ;;
        o)
            OUTPUT_DIR="${OPTARG}"
            # Currently it does not work correctly
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))
[ $# -gt 0 ] && usage  # exit if unknown argument found
echo "======outputdir"
echo ${OUTPUT_DIR}

if [ -n "${OUTPUT_DIR}" ]; then
    echo "cd ${OUTPUT_DIR}"
    $(cd ${OUTPUT_DIR})
    echo $?
fi
echo $(pwd)

for file in $FILEPATH; do
    if [[ $file == *".bag" ]]; then
        echo "[INFO] Make map from ${file}"
        make_map
    fi
done
