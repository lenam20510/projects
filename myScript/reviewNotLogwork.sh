#! /bin/sh

#
# Author: Duc Nguyen <ducmnguyen@gcs-vn.com>
#

function usage () {
  echo "<this script> -num-ticket [100|500|...]"
}

main() {
    local jira_query_string="project = \"DTVUS - STB Development\" and \"Effort Category\" in (Review) and Status != Closed and resolution in (Done, Unresolved) AND issueFunction in aggregateExpression(\"Total Time Spent\", \"timeSpent.sum()\") AND timespent is EMPTY  ORDER BY updated DESC"
    local max_search_results=50

    local GCS_JIRA_USERNAME=
    local GCS_JIRA_PASSWORD=

    while [ "$1" != "" ]; do
        case "$1" in
            -num-ticket) shift; max_search_results=$1;;
            --help) usage; return 0;;
        esac
        shift
    done

    # Temporary directory
    if [ ! -d ~/gcsjira_review_ticket/ ]; then
        mkdir ~/gcsjira_review_ticket/
    fi
    cd ~/gcsjira_review_ticket/

    # Load jira username - password if any
    if [ -f ~/.jira/user.inf ]; then
        . ~/.jira/user.inf
    fi

    if [ "$GCS_JIRA_USERNAME" = "" ] || [ $GCS_JIRA_PASSWORD = "" ]; then
        read -es "Jira username: " GCS_JIRA_USERNAME
        read -es -p "password: " GCS_JIRA_PASSWORD
        echo ""
    fi

    JIRA_USERNAME=$GCS_JIRA_USERNAME
    JIRA_PASSWORD=$GCS_JIRA_PASSWORD

    # Find all gcs jira review ticket
    jira.sh gcs search -jql "$jira_query_string" -max-results $max_search_results -fields "assignee,description" > gcsjira.review_ticket.json

    cat gcsjira.review_ticket.json | jq '.issues[] | "\(.key) \(.fields.assignee.name) \(.fields.description)"' | sed "s/\"//g" | while read -r review_assignee; do
        local gcsjira_key=`echo $review_assignee | cut -d ' ' -f1`
        local assignee=`echo $review_assignee | cut -d ' ' -f2`
        local description=`echo $review_assignee | cut -d ' ' -f3`
        local workOutpuId=`echo -e $description | head -1`
        workOutpuId=`echo $workOutpuId | grep ".*CR-[A-Z]\+-[0-9]\+" --only-matching`
        if [ "$gcsjira_key" = "" ] || [ "$assignee" = "" ] || [ "$description" = "" ]; then
            echo "Unexpected Error. ($review_assignee)"
            continue
        fi

        if [ "$workOutpuId" = "null" ] || [ "$workOutpuId" = "" ]; then
            # Re-try if we have working ticket
            local review_for=
            if [ "$workOutpuId" = "" ]; then
                review_for=`echo -e $description | head -1 | grep "DRTVUS-[0-9]\+" --only-matching`
            fi
            if [ "$review_for" = "" ]; then
                jira.sh gcs issue -key $gcsjira_key -fields summary > ${gcsjira_key}.json
                review_for=`cat ${gcsjira_key}.json | jq '.fields.summary' | grep "DRTVUS-[0-9]\+" --only-matching`
            fi
            if [ "$review_for" != "" ]; then
               jira.sh gcs issue -key $review_for -fields customfield_10021 > ${review_for}.json
               workOutpuId=`cat ${review_for}.json | jq '.fields.customfield_10021' | sed "s/\"//g"`
            fi
            if [ "$workOutpuId" = "" ]; then
                echo "No work output id: $gcsjira_key"
                continue
            fi
        fi

        local fisheye_key=`echo $workOutpuId | rev | cut -d '/' -f 1 | rev`
        fisheye.sh getreviewers -id $fisheye_key > ${fisheye_key}.json
        # Don't use xml response format
        # xml_grep 'reviewer' ${fisheye_key}.xml --text_only | grep "${assignee}true" > /dev/null && {
        #     echo "Not logwork: ${assignee} $gcsjira_key"
        # }
        cat ${fisheye_key}.json | jq '.reviewer[] | select(.completed == true) | .userName' | sed "s/^\"\|\"$//g" | while read -r completed_reviewer; do
            if [ "$completed_reviewer" == "${assignee}" ]; then
                echo "Not logwork: ${assignee} https://gcsjira.cybersoft-vn.com/jira/browse/$gcsjira_key"
            fi
        done
        rm ${fisheye_key}.json
    done

    # Cleanup
    cd ~
    if ! $debug; then
        rm -r ~/gcsjira_review_ticket/
    fi

    # We are done!
    # notify-send "$jira jira $action done!"
}

########MAIN#########
debug=false

CURL_DEBUG=

JIRA_USERNAME=
JIRA_PASSWORD=
# gcsjira.cybersoft-vn.com/jira
# https://gcsjira.cybersoft-vn.com/fisheye
# https://gcsjira.cybersoft-vn.com/wiki
FISHEYE="gcsjira.cybersoft-vn.com/fisheye"

echo "$@" | grep "\-\-debug" > /dev/null && {
    debug=true
}

if $debug; then
    CURL_DEBUG="-D- -v"
else
    # -s/--silent        Silent mode. Don't output anything
    CURL_ERROR_REDIRECT="--silent"
fi

FISHEYE_CURL() {
    local fisheye_curl_retval=0
    local proxy_option="--noproxy $FISHEYE"
    local insecure_option="-k"

    curl $CURL_DEBUG $insecure_option -u ${JIRA_USERNAME}:${JIRA_PASSWORD} $proxy_condition "$@" $CURL_ERROR_REDIRECT

    # Error
    if [ ! $? ]; then
        echo "FAILED"
        echo "Try with \"--debug\""
        fisheye_curl_retval=1
    fi

    return $fisheye_curl_retval
}

FISHEYE_CURL_CLEANUP() {
    if $debug; then
        return 0
    fi
}

#---------------------------------------------
main "$@"

