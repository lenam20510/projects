#! /bin/sh

#
# Author: Duc Nguyen <ducmnguyen@gcs-vn.com>
# Brief: JIRA REST API
#        - DTV Jira
#        - GCS Jira
#

function usage() {
   if [ "$1" = "" ]; then
       echo "<this script> [dtv|gcs] [action] -key [HDG*] [OPTION]"
       echo "Action help: <this script> [dtv|gcs] [action] --help"
       echo "[ getIssue createIssue deleteIssue watch stopWatch comment editComment deleteComment resolve assign link logwork getWorklog editWorklog deleteWorklog search ]"
       return 0
   fi

   case "$1" in
       assign)
           echo "<this script> assign -key [HDG*] -assignee [assignee]"
       ;;
       comment)
           echo "<this script> comment -key [HDG*] -comment [comment string] -comment-file [path to comment file]"
       ;;
       getcomment)
           echo "<this script> getcomment -key [HDG*]"
       ;;
       editcomment)
           echo "<this script> editcomment -key [HDG*] -comment [comment string] -comment-file [path to comment file] -comment-id [id]"
       ;;
       deletecomment)
           echo "<this script> deletecomment -key [HDG*] -comment-id [id]"
       ;;
       getissue)
           echo "<this script> getissue -key [HDG*] -fields [descriptioin,assignee]"
       ;;
       createissue)
           echo "<this script> createissue [OPTION]"
           echo "GCS Jira Only."
           echo -e "-project\t\tProject name or id"
           echo -e "-issue-type\t\tIssue type [Bug|Story|..]"
           echo -e "-summary\t\tSummary text"
           echo -e "-priority\t\tPriority [High|Midium|Low|...] (Default: Need Review)"
           echo -e "-component\t\tComponent (optional)"
           echo -e "-story_point\t\tStory point [1-6] (Default: 3)"
           echo -e "-affects-version\tAffects version (Optional)"
           echo -e "-reproducibility\tReproducibility [Always|Intermittent|...] (Required)"
           echo -e "-CID\t\t\tCID [P1|P2|...] (optional)"
           echo -e "-account\t\tCharge code (Required)"
           echo -e "-epic-link\t\tEpic link [DTVUS Integration|...] (Optinal)"
           echo -e "-description\t\tDescription text"
           echo -e "-assignee\t\tAssignee"
           echo -e "-cc-user\t\tCC user (optional)"
           echo -e "-due-date\t\tDue date [date] (Default: Current date +7 day)"
           echo -e "-estimate\t\tEstimate [2h|3d|1w|...] (Default: 3d)"
           echo -e "--help\t\t\tShow this help page."
       ;;
       deleteissue)
           echo "<this script> deleteissue -key [HDG*]"
       ;;
       logwork)
           echo "<this script> logwork -key [HDG*] -time-spent [time spent] -comment [comment string] -comment-file [path to comment file]"
           echo "Note: 1. Date format: date  +%Y-%m-%dT%T.%3N%z"
       ;;
       editworklog)
           echo "<this script> editworklog -key [HDG*] -time-spent [time spent] -comment [comment string] -comment-file [path to comment file] -worklog-id [id]"
           echo "Note: 1. Date format: date  +%Y-%m-%dT%T.%3N%z"
       ;;
       getworklog)
           echo "<this script> getworklog -key [HDG*]"
       ;;
       deleteworklog)
           echo "<this script> deleteworklog -key [HDG*] -worklog-id [id]"
       ;;
       search)
           echo "<this script> search -jql [Query string] -max-results"
       ;;
       watch)
           echo "<this script> watch -key [HDG*] -username [username]"
       ;;
       stopwatch)
           echo "<this script> stopwatch -key [HDG*] -username [username]"
       ;;
       link)
           echo "<this script> link -key [HDG*] -link-type [Duplicate|Related to|...] -comment [comment string] -comment-file [path to comment file] -link-id [id]"
       ;;
   esac
}

issueLink() {
    local jira_key=
    local link_type=
    local link_to_key=
    local cmt_string=
    local cmt_file=
    local method=
    local link_id=
    while [ "$1" != "" ]; do
      case "$1" in
        -key) shift; jira_key=$1;;
        -link-type) shift; link_type=$1;;
        -comment) shift; cmt_string="$1";;
        -comment-file) shift; cmt_file=$1;;
        -link-to) shift; link_to_key=$1;;
        -method) shift; method=$1;;
        -link-id) shift; link_id=$1;;
        --help) usage "link"; return 0;;
      esac
      shift
    done

    if [ "$jira_key" = "" ]; then
        usage "link"
        return 1
    fi

    # Read comment file
    if [ "$cmt_file" != "" ] && [ -f $cmt_file ]; then
        cmt_string="`cat $cmt_file | sed "s/$/\\\\\n/"`"
    fi

    if [ "$cmt_string" != "" ]; then
        cmt_string="$(echo "$cmt_string" | sed "s/\"/\\\\\\\"/g")"
    fi

    # Link issue
    if [ "$method" == "POST" ]; then
        echo "{" > $JSON_TMP_FILE
        echo "    \"type\": {" >> $JSON_TMP_FILE
        echo "        \"name\": \"$link_type\"" >> $JSON_TMP_FILE
        echo "    }," >> $JSON_TMP_FILE
        echo "    \"inwardIssue\": {" >> $JSON_TMP_FILE
        echo "        \"key\": \"$jira_key\"" >> $JSON_TMP_FILE
        echo "    }," >> $JSON_TMP_FILE
        echo "    \"outwardIssue\": {" >> $JSON_TMP_FILE
        echo "        \"key\": \"$link_to_key\"" >> $JSON_TMP_FILE
        echo "    }," >> $JSON_TMP_FILE
        echo "    \"comment\": {" >>  $JSON_TMP_FILE
        echo "        \"body\": \"$cmt_string\"" >> $JSON_TMP_FILE
        echo "    }" >> $JSON_TMP_FILE
        echo "}" >> $JSON_TMP_FILE

        if $debug; then
            cat $JSON_TMP_FILE
            return 0
        fi

        REST_CURL -X $method --data @$JSON_TMP_FILE $REST_LINK/issueLink/
    # Delete issue link
    elif [ "$method" == "DELETE" ]; then
        if [ "$link_id" = ]; then
            echo "Missing link id"
            usage "link"
            return 1
        fi
        REST_CURL -X $method $REST_LINK/issueLink/${link_id}
    # Get issue link
    elif [ "$method" == "GET" ]; then
        REST_CURL -X $method $REST_LINK/issueLink/${link_id}
    fi
}

watch() {
    local jira_key=
    local method=
    local action=
    local username=$JIRA_USERNAME

    while [ "$1" != "" ]; do
      case "$1" in
        -key) shift; jira_key=$1;;
        -action) shift; action="$1";;
        -username) shift; username=$1;;
        -method) shift; method=$1;;
        --help) usage "watch"; return 0;;
      esac
      shift
    done

    if [ "$jira_key" = "" ]; then
        usage "watch"
        return 1
    fi

    # Add watch
    if [ "$method" == "POST" ]; then
        REST_CURL -X $method --data "\"$username\"" $REST_LINK/issue/${jira_key}/watchers
    # Get watch
    elif [ "$method" == "GET" ]; then
        REST_CURL -X $method $REST_LINK/issue/${jira_key}/watchers
    # Remove/Stop watch
    elif [ "$method" == "DELETE" ]; then
        REST_CURL -X $method $REST_LINK/issue/${jira_key}/watchers?username=$username
    fi
}

filter() {
    local filter_id=
    local method=

    while [ "$1" != "" ]; do
      case "$1" in
        -filter-id) shift; filter_id=$1;;
        -method) shift; method=$1;;
        --help) usage "watch"; return 0;;
      esac
      shift
    done

    if [ "$filter_id" = "" ] && [ "$method" == "GET" ]; then
        usage "filter"
        return 1
    fi

    # Create filter
    if [ "$method" == "POST" ]; then
        echo "Not yet implement"
        return 1
        REST_CURL -X $method --data "\"$username\"" $REST_LINK/filter
    # Edit filter
    elif [ "$method" == "PUT" ]; then
        echo "Not yet implement"
        return 1
        REST_CURL -X $method --data "\"$username\"" $REST_LINK/filter/${filter_id}
    # Get filter
    elif [ "$method" == "GET" ]; then
        REST_CURL -X $method $REST_LINK/filter/${filter_id}
    # Delete filter by id
    elif [ "$method" == "DELETE" ]; then
        echo "Not yet implement"
        return 1
        REST_CURL -X $method $REST_LINK/filter/${filter_id}
    fi
}

search() {
    local jql=
    local startAt=0
    local max_results=50
    local method=
    local fields="summary,status,assignee"

    while [ "$1" != "" ]; do
        case "$1" in
            -jql)
                shift
                jql=$1
            ;;
            -startAt)
                shift
                startAt=$1
            ;;
            -max-results)
                shift
                max_results=$1
            ;;
            -method)
                shift
                method=$1;;
            -fields)
                shift
                fields=$1
            ;;
            --help) usage "search"; return 0;;
      esac
      shift
    done

    if [ "$jql" = "" ]; then
        echo "Missing query string."
        usage "search"
        return 1
    fi

    jql=`echo $jql | sed "s/\"/\\\\\\\\\"/g"`

    # Search
    if [ "$method" == "POST" ]; then
        # Json request format
        #{
        #    "jql": "project = HSP",
        #    "startAt": 0,
        #    "maxResults": 15,
        #    "fields": [
        #        "summary",
        #        "status",
        #        "assignee"
        #    ],
        #    "fieldsByKeys": false
        #}

        # Build JSON Object
        echo "{" > $JSON_TMP_FILE
        echo "  \"jql\": \"$jql\"," >> $JSON_TMP_FILE
        echo "  \"startAt\": $startAt," >> $JSON_TMP_FILE
        echo "  \"maxResults\": $max_results," >> $JSON_TMP_FILE
        echo "  \"fields\": [" >> $JSON_TMP_FILE
        # echo "     \"summary\"," >> $JSON_TMP_FILE
        # echo "     \"status\"," >> $JSON_TMP_FILE
        # echo "     \"assignee\"" >> $JSON_TMP_FILE
        if [ "$fields" != "" ]; then
        echo $fields | sed "s/^/\ \ \ \ \"/" | sed "s/$/\"/" | sed "s/,/\",\n\ \ \ \ \"/g" >> $JSON_TMP_FILE
        fi
        echo "  ]" >> $JSON_TMP_FILE
        echo "}" >> $JSON_TMP_FILE

        # DEBUG
        if $debug; then
            cat $JSON_TMP_FILE
            return 0
        fi

        REST_CURL -X $method --data @$JSON_TMP_FILE $REST_LINK/search
    fi
}

worklog() {
    local jira_key=
    local time_spent=
    local cmt_string=
    local method=
    local worklog_id=
    # `date  +%Y-%m-%dT%T.000%z --date="next Friday"`
    local started=
    while [ "$1" != "" ]; do
      case "$1" in
        -key) shift; jira_key=$1;;
        -comment) shift; cmt_string="$1";;
        -started) shift; started=$1;;
        -next-Friday) started=`date  +%Y-%m-%dT%T.000%z --date="next Friday"`;;
        -time-spent) shift; time_spent=$1;;
        -method) shift; method=$1;;
        -worklog-id) shift; worklog_id=$1;;
        --help)
            if [ "$method" = "POST" ]; then
                usage "logwork"
            elif [ "$method" = "PUT" ]; then
                usage "editworklog"
            elif [ "$method" = "GET" ]; then
                usage "editworklog"
            elif [ "$method" = "DELETE" ]; then
                usage "deleteworklog"
            fi
            return 0
      ;;
      esac
      shift
    done

    if [ "$jira_key" = "" ]; then
        echo "Missing jira key."
        if [ "$method" == "POST" ]; then
            usage "logwork"
        elif [ "$method" == "PUT" ]; then
            usage "editworklog"
        elif [ "$method" == "DELETE" ]; then
            usage "deleteworklog"
        fi
        return 1
    fi

    if [ "$cmt_string" != "" ]; then
        cmt_string=`echo $cmt_string | sed "s/\"/\\\\\\\\\"/g"`
    fi

    # Logwork
    if [ "$method" == "POST" ]; then
       # Json request format
       #{
       #    "comment": "I did some work here.",
       #    "visibility": {
       #        "type": "group",
       #        "value": "jira-developers"
       #    },
       #    "started": "2017-01-03T15:22:51.733+0000",
       #    "timeSpentSeconds": 12000
       #}

        if [ "$cmt_string" = "" ]; then
            echo "WARNING: Empty worklog description."
        fi

        if [ "$time_spent" = "" ]; then
            echo "Time spent can't be null."
            usage "logwork"
            return 1
        fi


        echo "{" > $JSON_TMP_FILE
        echo "  \"comment\": \"$cmt_string\"," >> $JSON_TMP_FILE
        if [ "$started" != "" ]; then
        echo "  \"started\": \"$started\"," >> $JSON_TMP_FILE
        fi
        echo "  \"timeSpent\": \"$time_spent\"" >> $JSON_TMP_FILE
        echo "}" >> $JSON_TMP_FILE

        if $debug; then
            cat $JSON_TMP_FILE
            return 0
        fi
        REST_CURL -X $method --data @$JSON_TMP_FILE $REST_LINK/issue/${jira_key}/worklog
    # Edit worklog
    elif [ "$method" == "PUT" ]; then
        if [ "$worklog_id" = "" ]; then
            echo "Missing worklog id."
            usage "editworklog"
            return 1
        fi

        if [ "$$time_spent" = "" ]; then
            echo "Time spent can't be null."
            usage "editworklog"
            return 1
        fi

        echo "{" > $JSON_TMP_FILE
        echo "  \"comment\": \"$cmt_string\"," >> $JSON_TMP_FILE
        if [ "$started" != "" ]; then
        echo "  \"started\": \"$started\"," >> $JSON_TMP_FILE
        fi
        echo "  \"timeSpent\": \"$time_spent\"" >> $JSON_TMP_FILE
        echo "}" >> $JSON_TMP_FILE

        if $debug; then
            cat $JSON_TMP_FILE
            return 0
        fi

        REST_CURL -X $method --data @$JSON_TMP_FILE $REST_LINK/issue/${jira_key}/worklog/${worklog_id}
    # Delete worklog
    elif [ "$method" == "DELETE" ]; then
        if [ "$worklog_id" = "" ]; then
            echo "Missing worklog id"
            usage "deleteworklog"
            return 1
        fi
        REST_CURL -X $method $REST_LINK/issue/${jira_key}/worklog/${worklog_id}
    # Get worklog
    elif [ "$method" == "GET" ]; then
        REST_CURL -X $method $REST_LINK/issue/${jira_key}/worklog
    fi
}

issue() {
    local jira_key=
    local method=
    local fields=
    local project=
    # Details
    local issue_type=
    local summary=
    local priority="Need Review"
    local component=None
    local story_point=3
    local affects_version=None
    local reproducibility=None
    local CID=None
    local account=None
    local epic_link=
    local description=
    # People
    local assignee=$JIRA_USERNAME
    local reporter=$JIRA_USERNAME
    local cc_user=None
    # Dates
    local due_date=`date  +%Y-%m-%d --date "+7 day"`
    local planned_start=`date  +%Y-%m-%d`
    local estimate="3d"

    while [ "$1" != "" ]; do
        case "$1" in
            -key) shift; jira_key=$1;;
            -project) shift; project=$1;;
            -issue-type) shift; issue_type=$1;;
            -summary) shift; summary=$1;;
            -priority) shift; priority=$1;;
            -component) shift; component=$1;;
            -story_point) shift; story_point=$1;;
            -affects-version) shift; affects_version=$1;;
            -reproducibility) shift; reproducibility=$1;;
            -CID) shift; CID=$1;;
            -account) shift; account=$1;;
            -epic-link) shift; epic_link="$1";;
            -description) shift; description=$1;;
            -assignee) shift; assignee=$1;;
            -reporter) shift; reporter=$1;;
            -cc-user) shift; cc_user=$1;;
            -due-date) shift; due_date=$1;;
            -planned-start) shift; planned_start=$1;;
            -estimate) shift; estimate=$1;;
            -fields)
                shift
                fields=$1
                if [ "$fields" = "None" ]; then
                    fields=versionedRepresentations
                fi
             ;;
            -method) shift; method=$1;;
            --help)
                if [ "$method" = "GET" ]; then
                    usage "getissue"
                elif [ "$method" = "POST" ]; then
                    usage "createissue"
                elif [ "$method" = "DELETE" ]; then
                    usage "deleteissue"
                else
                    usage
                fi
                return 0
           ;;
        esac
        shift
    done

    if [ "$jira_key" = "" ] && [ "$method" = "GET" ]; then
        echo "Missing jira key."
        usage "getissue"
        return 1
    fi

    if [ "$method" = "POST" ]; then
        if [ "$project" = "" ]; then
            echo "Missing project."
            usage "createissue"
            return 1
        fi
        if [ "$summary" = "" ]; then
            echo "Missing summary."
            usage "createissue"
            return 1
        fi
        if [ "$issue_type" = "" ]; then
            echo "Missing issue type."
            usage "createissue"
            return 1
        fi
        if [ "$description" = "" ]; then
            echo "Missing description."
            usage "createissue"
            return 1
        fi
    fi

    summary=`echo $summary | sed "s/\"/\\\\\\\\\"/g"`
    description=`echo $description | sed "s/\"/\\\\\\\\\"/g"`

    if [ "$fields" != "" ]; then
        fields="?fields=$fields"
    fi

    # Create issue
    if [ "$method" == "POST" ]; then
        # Json request format
        # {
        #     "update": {
        #         "worklog": [
        #             {
        #                 "add": {
        #                     "timeSpent": "60m",
        #                     "started": "2011-07-05T11:05:00.000+0000"
        #                 }
        #             }
        #         ]
        #     },
        #     "fields": {
        #         "project": {
        #             "id": "10000"
        #         },
        #         "summary": "something's wrong",
        #         "issuetype": {
        #             "id": "10000"
        #         },
        #         "assignee": {
        #             "name": "homer"
        #         },
        #         "reporter": {
        #             "name": "smithers"
        #         },
        #         "priority": {
        #             "id": "20000"
        #         },
        #         "labels": [
        #             "bugfix",
        #             "blitz_test"
        #         ],
        #         "timetracking": {
        #             "originalEstimate": "10",
        #             "remainingEstimate": "5"
        #         },
        #         "security": {
        #             "id": "10000"
        #         },
        #         "versions": [
        #             {
        #                 "id": "10000"
        #             }
        #         ],
        #         "environment": "environment",
        #         "description": "description",
        #         "duedate": "2011-03-11",
        #         "fixVersions": [
        #             {
        #                 "id": "10001"
        #             }
        #         ],
        #         "components": [
        #             {
        #                 "id": "10000"
        #             }
        #         ],
        #         "customfield_30000": [
        #             "10000",
        #             "10002"
        #         ],
        #         "customfield_80000": {
        #             "value": "red"
        #         },
        #         "customfield_20000": "06/Jul/11 3:25 PM",
        #         "customfield_40000": "this is a text field",
        #         "customfield_70000": [
        #             "jira-administrators",
        #             "jira-software-users"
        #         ],
        #         "customfield_60000": "jira-software-users",
        #         "customfield_50000": "this is a text area. big text.",
        #         "customfield_10000": "09/Jun/81"
        #     }
        # }

        # Build JSON Object
        echo "{" > $JSON_TMP_FILE
        echo "  \"update\": {" >> $JSON_TMP_FILE
        echo "    \"customfield_13110\": [{" >> $JSON_TMP_FILE
        echo "      \"set\": \"$account\"" >> $JSON_TMP_FILE
        echo "    }]," >> $JSON_TMP_FILE
        if [ "$issue_type" = "Story" ]; then
        echo "    \"customfield_12710\": [{" >> $JSON_TMP_FILE
        echo "      \"set\": { \"value\": \"$reproducibility\"}" >> $JSON_TMP_FILE
        echo "    }]," >> $JSON_TMP_FILE
        echo "    \"customfield_12417\": [{" >> $JSON_TMP_FILE
        echo "      \"set\": $story_point" >> $JSON_TMP_FILE
        echo "    }]," >> $JSON_TMP_FILE
        fi
        echo "    \"duedate\": [{" >> $JSON_TMP_FILE
        echo "      \"set\": \"$due_date\"" >> $JSON_TMP_FILE
        echo "    }]," >> $JSON_TMP_FILE
        echo "    \"timetracking\": [{" >> $JSON_TMP_FILE
        echo "      \"set\": {\"originalEstimate\": \"$estimate\"}" >> $JSON_TMP_FILE
        echo "    }]," >> $JSON_TMP_FILE
        echo "    \"description\": [{" >> $JSON_TMP_FILE
        echo "      \"set\": \"$description\"" >> $JSON_TMP_FILE
        echo "    }]" >> $JSON_TMP_FILE
        echo "  }," >> $JSON_TMP_FILE
        echo "  \"fields\": {" >> $JSON_TMP_FILE
        echo "    \"project\": {" >> $JSON_TMP_FILE
        echo $project | grep "^[0-9]\+$" > /dev/null && {
        echo "      \"id\": \"$project\"" >> $JSON_TMP_FILE
        } || {
        echo "      \"name\": \"$project\"" >> $JSON_TMP_FILE
        }
        echo "    }," >> $JSON_TMP_FILE
        echo "    \"summary\": \"$summary\"," >> $JSON_TMP_FILE
        echo "    \"issuetype\": {" >> $JSON_TMP_FILE
        echo $issue_type | grep "^[0-9]\+$" > /dev/null && {
        echo "      \"id\": \"$issue_type\"" >> $JSON_TMP_FILE
        } || {
        echo "      \"name\": \"$issue_type\"" >> $JSON_TMP_FILE
        }
        echo "    }," >> $JSON_TMP_FILE
        echo "    \"assignee\": {" >> $JSON_TMP_FILE
        echo "      \"name\": \"$assignee\"" >> $JSON_TMP_FILE
        echo "    }," >> $JSON_TMP_FILE
        # echo "    \"reporter\": {" >> $JSON_TMP_FILE
        # echo "      \"name\": \"$reporter\"" >> $JSON_TMP_FILE
        # echo "    }," >> $JSON_TMP_FILE
        echo "    \"priority\": {" >> $JSON_TMP_FILE
        echo "      \"name\": \"$priority\"" >> $JSON_TMP_FILE
        echo "    }," >> $JSON_TMP_FILE
        if [ "$epic_link" != "None" ] || [ "$epic_link" != "" ]; then
        echo "    \"customfield_12411\": \"$epic_link\"," >> $JSON_TMP_FILE
        fi
        if [ "$cc_user" != "" ]; then
        echo "    \"customfield_11711\": [" >> $JSON_TMP_FILE
        echo "        {" >> $JSON_TMP_FILE
        echo "          \"name\": \"$cc_user\"" >> $JSON_TMP_FILE
        echo "        }" >> $JSON_TMP_FILE
        echo "      ]" >> $JSON_TMP_FILE
        echo "    }," >> $JSON_TMP_FILE
        fi
        echo "    \"customfield_12912\": {" >> $JSON_TMP_FILE
        echo "      \"name\": \"$CID\"" >> $JSON_TMP_FILE
        echo "    }" >> $JSON_TMP_FILE
        echo "  }" >> $JSON_TMP_FILE
        echo "}" >> $JSON_TMP_FILE

        # DEBUG
        if $debug; then
            cat $JSON_TMP_FILE
            return 0
        fi

        REST_CURL -X $method --data @$JSON_TMP_FILE $REST_LINK/issue
    # Get transitions
    elif [ "$method" == "GET" ]; then
        if [ "$jira_key" == "" ]; then
            usage "getissue"
            return 1
        fi
        REST_CURL -X $method $REST_LINK/issue/${jira_key}${fields}
    elif [ "$method" == "DELETE" ]; then
        if [ "$jira_key" == "" ]; then
            usage "deleteissue"
            return 1
        fi
        REST_CURL -X $method $REST_LINK/issue/${jira_key}
    fi
}

comment() {
    local jira_key=
    local cmt_string=
    local cmt_file=
    local method=
    local comment_id=

    while [ "$1" != "" ]; do
      case "$1" in
        -key) shift; jira_key=$1;;
        -comment) shift; cmt_string="$1";;
        -comment-file) shift; cmt_file=$1;;
        -comment-id) shift; comment_id=$1;;
        -method) shift; method=$1;;
        --help) usage "comment"; return 0;;
      esac
      shift
    done

    if [ "$jira_key" = "" ]; then
        case "$method" in
            POST)
                usage "comment"
            ;;
            PUT)
                usage "editcomment"
            ;;
            GET)
                usage "getcomment"
            ;;
            DELETE)
                usage "deletecomment"
            ;;
            *)
                usage "comment"
            ;;
        esac
        return 1
    fi

    # Read comment file
    if [ "$cmt_file" != "" ] && [ -f $cmt_file ]; then
        cmt_string="`cat $cmt_file | sed "s/$/\\\\\n/"`"
    fi

    if [ "$cmt_string" != "" ]; then
        # cmt_string=`echo $cmt_string | sed "s/\"/\\\\\\\\\"/g"`
        cmt_string="$(echo $cmt_string | sed "s/\"/\\\\\\\"/g")"
    fi

    # Add comment
    if [ "$method" == "POST" ]; then
        # Json request format
        #{
        #    "body": "XXX",
        #    "visibility": {
        #        "type": "role",
        #        "value": "Administrators"
        #    }
        #}

        if [ "$cmt_string" = "" ]; then
            echo "Empty comment."
            usage "comment"
            return 1
        fi

        # Build JSON Object
        echo "{" > $JSON_TMP_FILE
        echo "    \"body\": \"$cmt_string\"" >> $JSON_TMP_FILE
        echo "}" >> $JSON_TMP_FILE

        # DEBUG
        if $debug; then
            cat $JSON_TMP_FILE
            # return 0
        fi

        REST_CURL -X $method --data @$JSON_TMP_FILE $REST_LINK/issue/${jira_key}/comment
    # Edit comment
    elif [ "$method" == "PUT" ]; then
        # Json request format
        #{
        #    "body": "XXX",
        #    "visibility": {
        #        "type": "role",
        #        "value": "Administrators"
        #    }
        #}

        if [ "$cmt_string" = "" ]; then
            echo "Empty comment."
            usage "comment"
            return 1
        fi
        if [ "$comment_id" = "" ]; then
            echo "Missing comment id"
            usage "editcomment"
            return 1
        fi 

        # Build JSON Object
        echo "{" > $JSON_TMP_FILE
        echo "    \"body\": \"$cmt_string\"" >> $JSON_TMP_FILE
        echo "}" >> $JSON_TMP_FILE

        # DEBUG
        if $debug; then
            cat $JSON_TMP_FILE
            return 0
        fi

        REST_CURL -X $method --data @$JSON_TMP_FILE $REST_LINK/issue/${jira_key}/comment/${comment_id}
    # Get comment
    elif [ "$method" == "GET" ]; then
        REST_CURL -X $method $REST_LINK/issue/${jira_key}/comment
    elif [ "$method" == "DELETE" ]; then
        if [ "$comment_id" = "" ]; then
            echo "Missign comment id."
            usage "deletecomment"
            return 1
        fi
        REST_CURL -X $method $REST_LINK/issue/${jira_key}/comment/${comment_id}
    fi
}

assign() {
    local jira_key=
    local assignee=
    local method=PUT

    while [ "$1" != "" ]; do
      case "$1" in
        -key) shift; jira_key=$1;;
        -assignee) shift; assignee=$1;;
        #-method) shift; method=$1;;
        --help) usage; return 0;;
      esac
      shift
    done

    if [ "$jira_key" = "" ] || [ "$assignee" = "" ]; then
        usage "assign"
        return 1
    fi

    # Assign
    if [ "$method" == "PUT" ]; then
        # Json request format
        # {
        #    "name": "harry"
        # }

        # Build JSON Object
        echo "{" > $JSON_TMP_FILE
        echo "    \"name\": \"$assignee\"" >> $JSON_TMP_FILE
        echo "}" >> $JSON_TMP_FILE

        # DEBUG
        if $debug; then
            cat $JSON_TMP_FILE
            # return 0
        fi

        REST_CURL -X $method --data @$JSON_TMP_FILE $REST_LINK/issue/${jira_key}/assignee
    fi
}

do_transition() {
    local jira_key=
    local trans_action=
    local assignee=
    local resolution=
    local issue_status=
    local cmt_string=
    local cmt_file=
    local method=
    local transitionId=
    local trans_expand=

    while [ "$1" != "" ]; do
      case "$1" in
        -key) shift; jira_key=$1;;
        -action) shift; trans_action=$1;;
        -comment) shift; cmt_string="$1";;
        -comment-file) shift; cmt_file=$1;;
        -method) shift; method=$1;;
        -assignee) shift; assignee=$1;;
        -resolution) shift; resolution=$1;;
        -status) shift; issue_status=$1;;
        -transition-id) shift; transitionId=$1;;
        --help) usage "do_transition"; return 0;;
      esac
      shift
    done

    # just support Resolve Issue"
    if [ "$jira_key" = "" ] || ( [ "$resolution" = "" ] && [ "$issue_status" = "" ] ); then
        usage "do_transition"
        return 1
    fi

    # Read comment file
    if [ "$cmt_file" != "" ] && [ -f $cmt_file ]; then
        cmt_string="`cat $cmt_file | sed "s/$/\\\\\n/"`"
    fi

    if [ "$cmt_string" != "" ]; then
        # cmt_string=`echo $cmt_string | sed "s/\"/\\\\\\\\\"/g"`
        cmt_string="$(echo $cmt_string | sed "s/\"/\\\\\\\"/g")"
    fi

    # Fields
    if [ "$assignee" != "" ] || [ "$resolution" != "" ] || [ "$issue_status" != "" ] || [ "$method" == "GET" ]; then
        trans_expand="?expand=transitions.fields"
    fi

    # Do transition
    if [ "$method" == "POST" ]; then
        # Json request format
        #{
        #    "update": {
        #        "comment": [
        #            {
        #                "add": {
        #                    "body": "Bug has been fixed."
        #                }
        #            }
        #        ]
        #    },
        #    "fields": {
        #        "assignee": {
        #            "name": "bob"
        #        },
        #        "resolution": {
        #            "name": "Fixed"
        #        }
        #    },
        #     "transition": {
        #        "id": "5"
        #    }
        #}

        # Build JSON Object
        echo "{" > $JSON_TMP_FILE
        # Update
        if [ "$cmt_string" != "" ]; then
        echo "  \"update\": {" >> $JSON_TMP_FILE
        echo "    \"comment\": [" >> $JSON_TMP_FILE
        echo "       {" >> $JSON_TMP_FILE
        echo "         \"add\": {" >> $JSON_TMP_FILE
        echo "             \"body\": \"$cmt_string\"" >> $JSON_TMP_FILE
        echo "          }" >> $JSON_TMP_FILE
        echo "       }" >> $JSON_TMP_FILE
        echo "     ]" >> $JSON_TMP_FILE
        echo "  }," >> $JSON_TMP_FILE
        fi
        # Fields
        echo "  \"fields\": {" >> $JSON_TMP_FILE
        if [ "$assignee" != "" ]; then
        echo "     \"assignee\": {" >> $JSON_TMP_FILE
        echo "        \"name\": \"$assignee\"" >> $JSON_TMP_FILE
        echo "     }," >> $JSON_TMP_FILE
        fi
        echo "     \"resolution\": {" >> $JSON_TMP_FILE
        if [ "$resolution" != "" ]; then
        echo "        \"name\": \"$resolution\"" >> $JSON_TMP_FILE
        fi
        echo "     }" >> $JSON_TMP_FILE
        echo "  }," >> $JSON_TMP_FILE
    # Transition id
        echo "  \"transition\": {" >> $JSON_TMP_FILE
        echo "    \"id\": \"5\"" >> $JSON_TMP_FILE
        echo "  }" >> $JSON_TMP_FILE
    # Done
        echo "}" >> $JSON_TMP_FILE

        if [ "$issue_status" != "" ]; then
            cp $JSON_TMP_FILE ${JSON_TMP_FILE}.tmp
            cat ${JSON_TMP_FILE}.tmp | jq ".update.status = \"$issue_status\"" >  $JSON_TMP_FILE
        fi

        # DEBUG
        if $debug; then
            cat $JSON_TMP_FILE
            return 0
        fi

        REST_CURL -X $method --data @$JSON_TMP_FILE $REST_LINK/issue/${jira_key}/transitions${trans_expand}
    # Get transitions
    elif [ "$method" == "GET" ]; then
        local transitionId_data=
        if [ "$transitionId" != "" ]; then transitionId_data="--data \"$transitionId\""; fi
        REST_CURL -X $method $transitionId_data $REST_LINK/issue/${jira_key}/transitions${trans_expand}
    fi
}

main() {
    local jira=$1
    shift
    local action=$1
    shift

    local DTV_JIRA_USERNAME=
    local DTV_JIRA_PASSWORD=

    local GCS_JIRA_USERNAME=
    local GCS_JIRA_PASSWORD=

    # Load jira username - password if any
    if [ -f ~/.jira/user.inf ]; then
        . ~/.jira/user.inf
    fi

    # Verify
    if [ "$jira" = "" ]; then
        echo "Which jira? [dtv|gcs]"
        usage
        return 1
    fi
    if [ "$action" = "" ]; then
        echo "Which action?"
        usage
        return 1
    fi

    # Which is jira?
    case "$jira" in
        dtv)
            if [ "$DTV_JIRA_USERNAME" = "" ] || [ $DTV_JIRA_PASSWORD = "" ]; then
                read -e -p "Jira username: " DTV_JIRA_USERNAME
                read -es -p "password: " DTV_JIRA_PASSWORD
                echo ""
            fi
            JIRA_USERNAME=$DTV_JIRA_USERNAME
            JIRA_PASSWORD=$DTV_JIRA_PASSWORD
            JIRA="jira.dtvops.net"
            REST_LINK="https://${JIRA}/rest/api/2"
        ;;
        gcs)
            if [ "$GCS_JIRA_USERNAME" = "" ] || [ $GCS_JIRA_PASSWORD = "" ]; then
                read -es "Jira username: " GCS_JIRA_USERNAME
                read -es -p "password: " GCS_JIRA_PASSWORD
                echo ""
            fi
            JIRA_USERNAME=$GCS_JIRA_USERNAME
            JIRA_PASSWORD=$GCS_JIRA_PASSWORD
            JIRA="gcsjira.cybersoft-vn.com/jira"
            REST_LINK="https://${JIRA}/rest/api/2"
        ;;
        *)
            echo "Unkown jira ($jira)"
            usage
            return 1
        ;;
    esac

    # Which is action? Perform it!
    action=`echo $action | tr '[:upper:]' '[:lower:]'` 
    case "$action" in
        issue)
            # same as getissue
            issue -method GET "$@"
        ;;
        getissue)
            issue -method GET "$@"
        ;;
        createissue)
            if [ "$jira" = "dtv" ]; then
                echo "Unsupport creating issue on DTV Jira."
                return 1
            fi
            issue -method POST "$@"
        ;;
        deleteissue)
            if [ "$jira" = "dtv" ]; then
                echo "Unsupport delete issue on DTV Jira."
                return 1
            fi
            issue -method DELETE "$@"
        ;;
        watch)
            watch -method POST "$@"
        ;;
        stopwatch|deletewatch)
            watch -method DELETE "$@"
        ;;
        comment)
            comment -method POST "$@"
        ;;
        getcomment)
            comment -method GET "$@"
        ;;
        editcomment)
            comment -method PUT "$@"
        ;;
        deletecomment)
            comment -method DELETE "$@"
        ;;
        resolve)
            do_transition -method POST "$@"
        ;;
        startprogress)
            do_transition -method POST "$@" -status "In Progress"
        ;;
        stopprogress)
            do_transition -method POST "$@" -status "Open"
        ;;
        assign)
            assign -method PUT "$@"
        ;;
        link)
            issueLink -method POST "$@"
        ;;
        logwork)
            worklog -method POST "$@"
        ;;
        editworklog)
            worklog -method PUT "$@"
        ;;
        getworklog)
            worklog -method GET "$@"
        ;;
        deleteworklog)
            worklog -method DELETE "$@"
        ;;
        getfilter)
            filter -method GET "$@"
        ;;
        search)
            search -method POST "$@"
        ;;
        --help)
            usage
            return 0
        ;;
        *)
            echo "Invalid action ($action)"
            usage
            return 1
        ;;
    esac

    # Cleanup
    if [ -f ${JSON_TMP_FILE} ]; then
        rm ${JSON_TMP_FILE}*
    fi

    # We are done!
    # notify-send "$jira jira $action done!"
}

#-------------------------------------------------
debug=false
js_res_reformat=true

CURL_DEBUG=
CURL_ERROR_REDIRECT=

JIRA_USERNAME=
JIRA_PASSWORD=
# jira.dtvops.net | gcsjira.cybersoft-vn.com/jira
# https://gcsjira.cybersoft-vn.com/fisheye
# https://gcsjira.cybersoft-vn.com/wiki
JIRA=
REST_LINK=

JSON_TMP_FILE=~/jira_json_`date +%s`.tmp

echo "$@" | grep "\-\-debug" > /dev/null && {
    debug=true
}

if $debug; then
    CURL_DEBUG="-D-"
else
    # -s/--silent        Silent mode. Don't output anything
    CURL_ERROR_REDIRECT="--silent"
fi

REST_CURL() {
    local rest_curl_retval=0
    local proxy_option="--noproxy $JIRA"
    local insecure_option=
    echo $JIRA | grep "gcs" > /dev/null && {
        insecure_option="-k"
        proxy_option="`echo $proxy_option | rev | cut -d '/' -f2- | rev`"
    }

    local json_response=`curl $CURL_DEBUG $insecure_option -u ${JIRA_USERNAME}:${JIRA_PASSWORD} -H "Content-Type: application/json" $proxy_option "$@" $CURL_ERROR_REDIRECT` 

    # Error
    if [ ! $? ]; then
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

    if [ -f $JSON_TMP_FILE ]; then
        rm $JSON_TMP_FILE
    fi
}

#---------------------------------------------
main "$@"

