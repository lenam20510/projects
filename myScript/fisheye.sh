#! /bin/sh

#
# Author: Duc Nguyen <ducmnguyen@gcs-vn.com>
# Brief: FISHEYE REST API
#

function usage() {
   if [ "$1" = "" ]; then
       echo "<this script> [action] -key [CR-*] [OPTION]"
       echo "Action help: <this script> [action] --help"
       echo "[ getReviewer ]"
       return 0
   fi

   # case "$1" in
   # esac
}

createReview() {
    local project_key="DTVUS STB Development"
    local summary=
    local jiraIssueKey=
    local changesetData=
    local repository=
    local author=$GCS_JIRA_USERNAME
    # local reviwer=

    while [ "$1" != "" ]; do
        case "$1" in
            -project)
                shift
                project_key=$1
            ;;
            -summary)
                shift
                summary=$1
            ;;
            -linked-issue)
                shift
                jiraIssueKey=$1
            ;;
            -changeset-data)
                shift
                changesetData=$1
            ;;
            -repository)
                shift
                repository=$1
            ;;
            -author)
                shift
                author=$1
            ;;
            --help)
                usage "createReview"
                return 0
            ;;
            *)
                echo "Unknown option ($1)"
                usage "createReview"
                return 1
            ;;
        esac
        shift
    done
    
    # Json Request format
    #{
    #  "reviewData" : {
    #    "projectKey" : "CR-FOO",
    #    "name" : "Example review.",
    #    "description" : "Description or statement of objectives for this example review.",
    #    "author" : {
    #      "userName" : "joe",
    #      "displayName" : "Joe Krustofski",
    #      "avatarUrl" : "http://foo.com/avatar"
    #    },
    #    "moderator" : {
    #      "userName" : "scott",
    #      "displayName" : "Scott the Moderator",
    #      "avatarUrl" : "http://foo.com/avatar"
    #    },
    #    "creator" : {
    #      "userName" : "joe",
    #      "displayName" : "Joe Krustofski",
    #      "avatarUrl" : "http://foo.com/avatar"
    #    },
    #    "permaId" : {
    #      "id" : "CR-FOO-21"
    #    },
    #    "permaIdHistory" : [ "CR-FOO-21" ],
    #    "summary" : "some review summary.",
    #    "state" : "Review",
    #    "type" : "REVIEW",
    #    "allowReviewersToJoin" : true,
    #    "metricsVersion" : 4,
    #    "createDate" : "2016-11-09T17:06:01.860+0100",
    #    "dueDate" : "2016-11-10T17:06:01.860+0100",
    #    "jiraIssueKey" : "FOO-6754"
    #  },
    #  "patch" : "Index: emptytests/notempty/a.txt\n===================================================================\ndiff -u -N -r1.31 -r1.32\n--- emptytests/notempty/a.txt\t22 Sep 2004 00:38:15 -0000\t1.31\n+++ emptytests/notempty/a.txt\t5 Dec 2004 01:04:25 -0000\t1.32\n@@ -4,4 +4,5 @@\n hello there :D\n CRU-123\n http://madbean.com/blog/\n-!\n\\ No newline at end of file\n+!\n+foobie\n\\ No newline at end of file\nIndex: test/a.txt\n===================================================================\ndiff -u -N -r1.31 -r1.32\n--- test/a.txt\t22 Sep 2004 00:38:15 -0000\t1.31\n+++ test/a.txt\t5 Dec 2004 01:04:25 -0000\t1.32\n@@ -4,4 +4,5 @@\n hello there :D\n CRU-123\n http://madbean.com/blog/\n-!\n\\ No newline at end of file\n+!\n+foobie\n\\ No newline at end of file",
    #  "anchor" : {
    #    "anchorPath" : "/",
    #    "anchorRepository" : "REPO",
    #    "stripCount" : 2
    #  },
    #  "changesets" : {
    #    "changesetData" : [ {
    #      "id" : "63452"
    #    } ],
    #    "repository" : "REPO"
    #  }
    #}

    # Build Json Object
    echo "{" > $JSON_TMP_FILE
    echo "  \"reviewData\" : {" >> $JSON_TMP_FILE
    echo "  }" >> $JSON_TMP_FILE
    echo "}" >> $JSON_TMP_FILE
}

reviewers() {
   local fisheye_id=
   local reviewer=
   local iscompleted=
    while [ "$1" != "" ]; do
      case "$1" in
        -id) shift; fisheye_id=$1;;
        -method) shift; method=$1;;
        -reviewer) shift; reviewer=$1;;
        -completed) shift; if $1; then iscompleted=completed; else iscompleted=uncompleted; fi;;
        --help) usage; return 0;;
      esac
      shift
    done

    if [ "$fisheye_id" == "" ]; then
        usage
        return 1
    fi

    if [ "$method" = "GET" ]; then
        REST_CURL -X $method $transitionId_data $REST_LINK/rest-service/reviews-v1/${fisheye_id}/reviewers/${iscompleted}
    fi
}


main() {
    local action=$1
    shift

    local GCS_JIRA_USERNAME=
    local GCS_JIRA_PASSWORD=

    # Load jira username - password if any
    if [ -f ~/.jira/user.inf ]; then
        . ~/.jira/user.inf
    fi

    # Verify
    if [ "$action" = "" ]; then
        echo "Which action?"
        usage
        return 1
    fi

    if [ "$GCS_JIRA_USERNAME" = "" ] || [ $GCS_JIRA_PASSWORD = "" ]; then
        read -es "Jira username: " GCS_JIRA_USERNAME
        read -es -p "password: " GCS_JIRA_PASSWORD
        echo ""
    fi

    JIRA_USERNAME=$GCS_JIRA_USERNAME
    JIRA_PASSWORD=$GCS_JIRA_PASSWORD
    FISHEYE="gcsjira.cybersoft-vn.com/fisheye"
    REST_LINK="https://$FISHEYE"

    # Which is action? Perform it!
    action=`echo $action | tr '[:upper:]' '[:lower:]'`
    case "$action" in
        getreviewers)
            reviewers "$@" -method GET
        ;;
        *)
            echo "Invalid action ($action)"
            usage
            return 1
        ;;
    esac

    # We are done!
    # notify-send "Fisheye done!"
}

########MAIN#########
debug=false
js_res_reformat=true

CURL_DEBUG=
CURL_ERROR_REDIRECT=

JIRA_USERNAME=
JIRA_PASSWORD=
REST_LINK=
JSON_TMP_FILE=~/fisheye_json_`date +%s`.tmp

echo "$@" | grep "\-\-debug" > /dev/null && {
    debug=true
}

if $debug; then
    CURL_DEBUG="-D-"
else
    # -s/--silent        Silent mode. Don't output anything
    # CURL_ERROR_REDIRECT="2 \> $REST_CURL_ERROR_TMP_FILE"
    CURL_ERROR_REDIRECT="--silent"
fi

REST_CURL() {
    local rest_curl_retval=0
    local proxy_option="--noproxy gcsjira.cybersoft-vn.com"
    local insecure_option="-k"

    local json_response=`curl $CURL_DEBUG $insecure_option -u ${JIRA_USERNAME}:${JIRA_PASSWORD} -H "Accept: application/json" $proxy_option "$@" $CURL_ERROR_REDIRECT`

    # Error
    if [ ! $? ] && [ ! $debug ]; then
        echo "FAILED"
        echo "Try with \"--debug\""
        rest_curl_retval=1
    fi

    # Successed and have json response
    if [ "$json_response" != "" ]; then
        echo $json_response | grep "DOCTYPE HTML" > /dev/null && {
            echo $json_response
            # Newline
            echo ""
        } || {
            if $js_res_reformat; then
                echo $json_response | json_reformat
            else
                echo $json_response
            fi
        }
    fi

    REST_CURL_CLEANUP
    return $rest_curl_retval
}

REST_CURL_CLEANUP() {
    if $debug; then
        return 0
    fi
}

#---------------------------------------------
main "$@"

