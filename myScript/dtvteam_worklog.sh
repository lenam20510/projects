#! /bin/sh

# @Author: Duc Nguyen <ducmnguyen@gcs-vn.com>


usage() {
    echo "<this script> -leader [team leader]"
    echo -e "-leader\tTeam leader (Default: chuyenlh)"
}

main() {
    local timezone="Asia/Ho_Chi_Minh"
    local start_date="$(TZ=$timezone date +%b) 01"
    if [[ $(TZ=$timezone date +%d) -le 7 ]]; then
         start_date="$(TZ=$timezone date +%b --date "-1 month") 01"
    fi
    local start_date_second=$(TZ=$timezone date +%s --date "$start_date")
    local end_date=$(date "+%b %d" --date "$(TZ=$timezone date +%b --date "$mdate +1 month") 01")
    local end_date_second=$(TZ=$timezone date +%s --date "$end_date")

    mdate=$start_date
    local output_format=","
    while [ "$mdate" != "$end_date" ]; do
        output_format="${output_format}${mdate}:0,"
        if [ "$(TZ=$timezone date +%a --date "${mdate}")" = "Sun" ]; then
            output_format="${output_format}$(TZ=$timezone date +W%V:0 --date "${mdate}"),"
        fi
        if [ "$mdate" = "$(TZ=$timezone date "+%b %d" --date "$mdate +1 month -1 day")" ]; then
            output_format="${output_format}$(TZ=$timezone date "+%b:0" --date "$mdate"),"
        fi
        local end_month_date=$(date "+%b %d" --date "$(TZ=$timezone date +%b --date "$mdate +1 month") 01 -1 day")
        if [ "$mdate" = "$end_month_date" ]; then
            output_format="${output_format}$(TZ=$timezone date "+%b:0" --date "$(TZ=$timezone date +%b --date "$mdate +1 month") 01 -1 day"),"
        fi
        
        mdate=$(TZ=$timezone date "+%b %d" --date "$mdate +1 day")
    done

    while [ "$1" != "" ]; do
        case "$1" in
            -leader)
                shift
                TEAM_LEADER=$1
            ;;
            --help)
                usage
                return 0
            ;;
            *)
                echo "Unknown option ($1)"
                usage
                return 1
            ;;
        esac
        shift
    done

    case "$TEAM_LEADER" in
        chuyenlh)
            DTV_ACCOUNT_LIST="chuyenlh ducmnguyen duynp dupham hasn hoanggpn quanbh"
            GCS_ACCOUNT_LIST="chuyenlh ducmnguyen duynp dupham hasn hoanggpn quanbh.tx"
            ACCOUNT_LIST="chuyenlh ducmnguyen duynp dupham hasn hoanggpn quanbh.tx"
        ;;
        chinhvn)
            DTV_ACCOUNT_LIST="chinhvn khangtmn taihv ht9974 vinhnh hungnhp nhannt"
            # Exception list:
            # DTV Account: taihv (Vo Huu Tai), ht9974 (Truong Thi Diem Huong)
            # GCS Account: thuanmp.ja, taihv.ti (Vo Huu Tai), nguyentd.ek, huongtdt.fj (Truong Thi Diem Huong)
            GCS_ACCOUNT_LIST="chinhvn khangtmn taihv.ti huongtdt.fj vinhnh hungnhp nhannt nguyentd.ek thuanmp.ja"
            ACCOUNT_LIST="chinhvn khangtmn taihv.ti huongtdt.fj vinhnh hungnhp nhannt nguyentd.ek thuanmp.ja"
        ;;
        *)
            echo "Unknown team leader ($TEAM_LEADER)"
            usage
            return 1
        ;;
    esac

    REPORT_FILE_NAME=~/${TEAM_LEADER}_team_worklog.cvs
    

    # We will work in unser directory
    cd ~

    local column_name=`echo $output_format | sed "s/^,\|:0//g"`
    column_name=`echo $column_name | sed -e 's/\([A-Z][a-z]*\ [0-9]*\)/echo "$(date +%a --date "\1")\ \1"/ge' | sed "s/echo\ //g"`
    echo "Username,$column_name" > ${TEAM_LEADER}_team.worklog.csv

    local jira_names="dtv gcs"

    # Output format: dtv_chuyenlh,Feb 01:0,Feb 02:0,Feb 03:0,Feb 04:0,Feb 05:0,W05:0,Feb 06:0,Feb 07:0,Feb 08:0,Feb 09:0,Feb 10:0,Feb 11:0,Feb 12:0,W06:0,Feb 13:0,Feb 14:0,Feb 15:0,Feb 16:0,Feb 17:0,Feb 18:0,Feb 19:0,W07:0, 
    # Calculate Example: sed -e 's/\(dtv_.*,\)\(.*\)\(W05:\)\([0-9]\+\)\(,.*\)/echo "\1\2\3$(( \4 + 1 ))\5"/ge'
    for team_member in $ACCOUNT_LIST; do
        for jira_name in $jira_names; do
            echo "${jira_name}_${team_member}$output_format" >> ${TEAM_LEADER}_team.worklog.csv
        done
    done

    for jira_name in $jira_names; do
        # DEBUG
        # if [ "$jira_name" == "dtv" ]; then continue; fi

        local account_list=
        local jql_string=
        local jq_string=
        local errorMessages=
        local warningMessages=
        if [ "$jira_name" == "dtv" ]; then
            local worklogAuthors=`echo $DTV_ACCOUNT_LIST | sed "s/^\|$/\"/g" | sed "s/\ /\",\"/g"`
            jql_string="worklogAuthor in ($worklogAuthors) AND updatedDate >= \"$(date "+%Y/%m/%d" --date "$start_date -1 day")\" ORDER BY updated DESC"
            jq_string='.fields.worklog.worklogs[] | "\(.author.name),\(.started),\(.timeSpentSeconds),\(.updateAuthor.timeZone),\(.id)"'
        else
            account_list=`echo $GCS_ACCOUNT_LIST | sed "s/^\|$/\"/g" | sed "s/\ /\",\"/g"`
            jql_string="(assignee was in ($account_list) OR watcher in ($account_list) OR \"CC Users\" in (\"$TEAM_LEADER\")) AND updatedDate >= \"$(date "+%Y/%m/%d" --date "$start_date -1 day")\" AND issueFunction in aggregateExpression(\"Total Time Spent\", \"timeSpent.sum()\") AND timespent is not EMPTY ORDER BY updated DESC"
            jq_string='.fields.worklog.worklogs[] | "\(.author.name),\(.started),\(.timeSpentSeconds),\(.id)"'
        fi

        jira.sh $jira_name search -jql "$jql_string" -fields worklog -max-results -1 > ${jira_name}.worklog.json

        errorMessages=`cat ${jira_name}.worklog.json | jq '.errorMessages'`
        if [ "$errorMessages" != "null" ]; then
            echo $errorMessages
            continue
        fi
        warningMessages=`cat ${jira_name}.worklog.json | jq '.warningMessages'`
        if [ "$warningMessages" != "null" ]; then
            echo $warningMessages
        fi

        # Fix worklog expand limit (max 20)
        # List of issue have more than 20 worklogs
        over20worklog_keys=`cat ${jira_name}.worklog.json | jq '.issues[] | select(.fields.worklog.total > .fields.worklog.maxResults) | .key' | sed "s/^\"\|\"$//g"`
        for over20worklog_key in $over20worklog_keys; do
            jira.sh $jira_name getWorklog -key $over20worklog_key > ${over20worklog_key}.json
            errorMessages=`cat ${over20worklog_key}.json | jq '.errorMessages'`
            if [ "$errorMessages" != "null" ]; then
                echo $errorMessages
                continue
            fi
            warningMessages=`cat ${over20worklog_key}.json | jq '.warningMessages'`
            if [ "$warningMessages" != "null" ]; then
                echo $warningMessages
            fi
        done

        # Do filter on search results
        cat ${jira_name}.worklog.json | jq '.issues[] | select(.fields.worklog.total <= .fields.worklog.maxResults)' > ${jira_name}.worklog.filtered.json
        rm ${jira_name}.worklog.json

        if [ -f ${TEAM_LEADER}_team.${jira_name}.worklog.tmp.csv ]; then
            rm ${TEAM_LEADER}_team.${jira_name}.worklog.tmp.csv
        fi

        local json_files="${jira_name}.worklog.filtered $over20worklog_keys"
        for json_file in $json_files; do
            local jq_worklog_filter=$jq_string
            if [[ ! "$json_file" =~ ${jira_name}* ]]; then
                jq_worklog_filter=`echo $jq_worklog_filter | sed "s/^\.fields\.worklog//"`
            fi 
            cat ${json_file}.json | jq "$jq_worklog_filter" | sed "s/\"//g" | while read -r worklog; do
                local worklog_date=`echo $worklog | cut -d ',' -f2 | sed "s/T/\ /"`
                worklog_date=`date +%s --date "$worklog_date"`
                if [[ $worklog_date -ge $start_date_second ]]; then
                    echo $worklog >> ${TEAM_LEADER}_team.${jira_name}.worklog.tmp.csv
                fi
            done
            rm ${json_file}.json
        done

        # Process worklog
        if [ -f ${TEAM_LEADER}_team.${jira_name}.worklog.tmp.csv ]; then
            cat ${TEAM_LEADER}_team.${jira_name}.worklog.tmp.csv | sort | uniq > ${TEAM_LEADER}_team.${jira_name}.worklog.csv
            rm ${TEAM_LEADER}_team.${jira_name}.worklog.tmp.csv
        fi

        # Exception
        if [ "$jira_name" == "dtv" ]; then
            # DTV Account: taihv (Vo Huu Tai), ht9974 (Truong Thi Diem Huong)
            # GCS Account: thuanmp.ja, taihv.ti (Vo Huu Tai), nguyentd.ek, huongtdt.fj (Truong Thi Diem Huong)
            sed -i "s/ht9974/huongtdt\.fj/g" ${TEAM_LEADER}_team.dtv.worklog.csv
            sed -i "s/taihv/taihv\.ti/g" ${TEAM_LEADER}_team.dtv.worklog.csv
            sed -i "s/quanbh/quanbh\.tx/g" ${TEAM_LEADER}_team.dtv.worklog.csv
        fi

        # Calculate
        cat ${TEAM_LEADER}_team.${jira_name}.worklog.csv | while read -r worklog; do
            local worklog_author=`echo $worklog | cut -d ',' -f1`
            local worklog_date_str=`echo $worklog | cut -d ',' -f2 | sed "s/T/\ /"`
            local worklog_timezone="Asia/Ho_Chi_Minh"
            if [ "$jira_name" = "dtv" ]; then
                worklog_timezone=`echo $worklog | cut -d ',' -f4`
                # echo $worklog | grep "Los_Angeles"
            fi
            worklog_date=$(TZ="$worklog_timezone" date "+%b %d" --date "$worklog_date_str")
            # DEBUG
            #if [ "$worklog_date" = "Feb 22" ]; then
            #    echo worklog=$worklog
            #fi
            worklog_week=$(TZ="$worklog_timezone" date "+W%V" --date "$worklog_date_str")
            worklog_month=$(TZ="$worklog_timezone" date "+%b" --date "$worklog_date_str")
            time_spent_second=`echo $worklog | cut -d ',' -f3`
            time_spent_hour=`echo scale=2\; "$time_spent_second / 3600" | bc`

            # Write it to file
            # \`echo 'scale=2;\4 + 1.2' | bc \
            local sed_cmd="s/\(${jira_name}_${worklog_author},\)\(.*\)\(${worklog_date}:\)\(\.\?[0-9]\+\.\?[0-9]*\)\(,.*\)/echo \"\1\2\3\`echo 'scale=2;\4 + $time_spent_hour' | bc\`\5\"/ge"
            sed -i -e "$sed_cmd" ${TEAM_LEADER}_team.worklog.csv

            # Sum by Week
            sed_cmd="s/\(${jira_name}_${worklog_author},\)\(.*\)\(${worklog_week}:\)\(\.\?[0-9]\+\.\?[0-9]*\)\(,.*\)/echo \"\1\2\3\`echo 'scale=2;\4 + $time_spent_hour' | bc\`\5\"/ge"
            sed -i -e "$sed_cmd" ${TEAM_LEADER}_team.worklog.csv

            # Sum by Month
            sed_cmd="s/\(${jira_name}_${worklog_author},\)\(.*\)\(${worklog_month}:\)\(\.\?[0-9]\+\.\?[0-9]*\)\(,.*\)/echo \"\1\2\3\`echo 'scale=2;\4 + $time_spent_hour' | bc\`\5\"/ge"
            sed -i -e "$sed_cmd" ${TEAM_LEADER}_team.worklog.csv
        done
        rm ${TEAM_LEADER}_team.${jira_name}.worklog.csv
    done

    # Remove key word
    sed -i "s/[A-Z][a-z]*\ *[0-9]*://g" ${TEAM_LEADER}_team.worklog.csv

    head -1 ${TEAM_LEADER}_team.worklog.csv > ${TEAM_LEADER}_team.worklog.analysis.csv
    local column_name=`head -1 ${TEAM_LEADER}_team.worklog.csv`
    column_name=`echo $column_name | sed "s/Username,//"`
    # Analysis
    for team_member in $ACCOUNT_LIST; do
        grep "dtv_${team_member}" ${TEAM_LEADER}_team.worklog.csv >> ${TEAM_LEADER}_team.worklog.analysis.csv
        grep "gcs_${team_member}" ${TEAM_LEADER}_team.worklog.csv >> ${TEAM_LEADER}_team.worklog.analysis.csv
        dtv_worklog=`grep "dtv_${team_member}" ${TEAM_LEADER}_team.worklog.csv | cut -d ',' -f2- | sed "s/,/\ /g"`
        gcs_worklog=`grep "gcs_${team_member}" ${TEAM_LEADER}_team.worklog.csv | cut -d ',' -f2- | sed "s/,/\ /g"`
        dtv_4_8_worklog="dtv_${team_member}_4_8,"
        gcs_4_8_worklog="gcs_${team_member}_4_8,"
        worklog_diff="${team_member}_diff,"
        column=1
        for dtv_work_hour in $dtv_worklog; do
            local get_gcs_worklog="echo $gcs_worklog | cut -d ' ' -f$column"
            local gcs_work_hour=`eval $get_gcs_worklog`
            local get_column_date="echo $column_name | cut -d ',' -f $column"
            local column_date=`eval $get_column_date`
            column=$((column +1))

            if [[ ! "$column_date" =~ ^W[0-9]+$ ]] && [[ ! "$column_date" =~ ^[A-Z][a-z]{2}$ ]]; then
                if [[ $(echo $dtv_work_hour'<'2 | bc -l) -eq 1 ]]; then
                    dtv_4_8_worklog="${dtv_4_8_worklog}0,"
                    dtv_work_hour=0
                elif [[ $(echo $dtv_work_hour'<'6 | bc -l) -eq 1 ]]; then
                    dtv_4_8_worklog="${dtv_4_8_worklog}4,"
                    dtv_work_hour=4
                else
                    dtv_4_8_worklog="${dtv_4_8_worklog}8,"
                    dtv_work_hour=8
                fi
                if [[ $(echo $gcs_work_hour'<'2 | bc -l) -eq 1 ]]; then
                    gcs_4_8_worklog="${gcs_4_8_worklog}0,"
                    gcs_work_hour=0
                elif [[ $(echo $gcs_work_hour'<'6 | bc -l) -eq 1 ]]; then
                    gcs_4_8_worklog="${gcs_4_8_worklog}4,"
                    gcs_work_hour=4
                else
                    gcs_4_8_worklog="${gcs_4_8_worklog}8,"
                    gcs_work_hour=8
                fi
                if [ $dtv_work_hour -ne $gcs_work_hour ]; then
                    worklog_diff="${worklog_diff}DIFF,"
                else
                    worklog_diff="${worklog_diff},"
                fi
            else
                dtv_4_8_worklog="${dtv_4_8_worklog}${dtv_work_hour},"
                gcs_4_8_worklog="${gcs_4_8_worklog}${gcs_work_hour},"
                worklog_diff="${worklog_diff},"
            fi

        done
        echo ${dtv_4_8_worklog} >> ${TEAM_LEADER}_team.worklog.analysis.csv
        echo ${gcs_4_8_worklog} >> ${TEAM_LEADER}_team.worklog.analysis.csv
        echo ${worklog_diff} >> ${TEAM_LEADER}_team.worklog.analysis.csv
    done

    # Cleanup

    # We have done
    return 0
}

#-----------------------
# Global variable
TEAM_LEADER=chuyenlh
DTV_ACCOUNT_LIST="chuyenlh ducmnguyen duynp dupham hasn hoanggpn quanbh"
GCS_ACCOUNT_LIST="chuyenlh ducmnguyen duynp dupham hasn hoanggpn quanbh.tx"
ACCOUNT_LIST="chuyenlh ducmnguyen duynp dupham hasn hoanggpn quanbh.tx"
REPORT_FILE_NAME=~/${TEAM_LEADER}_team.worklog.cvs

#-----------------------
main "$@"

