# Create GCS Jira ticket from DTV Jira tiket id

usage() {
    echo "<this script> -key [HDG...]"
}

main() {
    local jira_key=
    local rework=false

    while [ "$1" != "" ]; do
        case "$1" in
            -key)
                shift
                jira_key=$1
            ;;
            --rework)
                rework=true
            ;;
            --debug)
                debug=true
            ;;
            *)
                echo "Unknown args ($1)."
                usage
                return 1
            ;;
        esac
        shift
    done

    echo $jira_key | grep "^\(HDG\|HDGHMC\|HOS\)\+-[0-9]\+$" > /dev/null || {
        echo "Missing DTV Jira key ($jira_key)."
        usage
        return 1
    }

    # Get DTV Jira issue
    jira.sh dtv issue -key $jira_key -fields summary,priority,customfield_11856,customfield_10500 > ${jira_key}.json
    local summary=`cat ${jira_key}.json | jq '.fields.summary' | sed "s/\"//g"`
    local priority=`cat ${jira_key}.json | jq '.fields.priority.name' | sed "s/\"//g"`
    local CID=`cat ${jira_key}.json | jq '.fields.customfield_11856.name' | sed "s/\"//g"`
    local reproducibility=`cat ${jira_key}.json | jq '.fields.customfield_10500.name' | sed "s/\"//g"`
    if ! $rework; then
    summary="[ducmnguyen] $jira_key $summary"
    else
        summary="[ducmnguyen] [REWORK] $jira_key $summary"
    fi
    if [ "$priority" = "" ]; then
        priority="Need Review"
    fi
    if [ "$CID" = "null" ]; then
        CID="None"
    fi
    if [ "$reproducibility" = "null" ]; then
        reproducibility="Once"
    fi
    
    local description="https://jira.dtvops.net/browse/$jira_key"
    #DTVUS - STB Development
    local project="19242"

    local account=
    case "$jira_key" in
        HDG-*)
            # 463754 - STB HX2X ALLOCABLE
            account="463754"
        ;;
	HOS-*)
            # 463938 - DRE NOD Phase 2
            account="463938"
        ;;
    esac
    local epic_link="DTVUS Integration"

    local debug_opton=
    if $debug; then
        debug_opton="--debug"
    fi

    jira.sh gcs createIssue -project $project -issue-type Story -summary "$summary" -priority $priority -description $description -CID $CID -reproducibility $reproducibility -cc-user chuyenlh -account "$account" -epic-link "$epic_link" $debug_opton
}

#------------------------------------------------
debug=false
echo "$@" | grep "\-\-debug" > /dev/null && {
    debug=true
}

#--------------------------
main "$@"
