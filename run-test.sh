#!/bin/sh

# Call by `test-local.sh` or `test-docker.sh`

CURRENT_PATH=`pwd`

# mysql_test build
cd ${CURRENT_PATH}/tidb-test/mysql_test
sh build.sh

# Test case list
whitelist=`ls -l t | awk '{print $9}' | awk -F '.' '{print $1}' | 
    # legency
    grep -vE "^null$|^opt_hints$|^union$|^grant_explain_non_select$|^subquery_table_to_derived$|^sql_mode$|^group_by$|^type_temporal_fractional$|^information_schema_cs$|^subselect_innodb$|^partition_pruning$|^subquery_sj_all$|^subquery_mat_none$|^comment_index$|^group_min_max$|^join_nested$|^order_by_all$|^time_zone_grant$|^host_cache_size_functionality$|^type_blob$|^distinct$|^functional_index$|^opt_hints_index$|^desc_index_innodb$|^bench_count_distinct$|^create_not_windows$|^derived_ci$|^key_diff$|^rollback$|^subquery_exists$|^time_zone_with_dst$|^upd_del_single_to_multi$|^upgrade$" |
    # "create user" statement
    grep -vE "^bug58669$|^change_user$|^grant_dynamic$|^grant_explain_non_select$|^grant_lowercase_fs$|^host_cache_size_functionality$|^information_schema_cs$|^insert$|^lowercase_fs_off$|^lowercase_table_grant$|^lowercase_table4$|^multi_update$|^partition_grant$|^ps$|^reset_connection$|^role$|^role2$|^roles_bugs_wildcard$|^roles-ddl$|^roles-view$|^roles2$|^show_check_cs$|^sql_mode$|^time_zone_grant$|^user_if_exists$|^variables_dynamic_privs$|^view_grant$" | 
    # charset and collate not match
    grep -vE "^func_in_all$|^func_in_none$|^ctype_utf8$|^distinct$|^func_str$|^range_all$" |
    # load stats not support
    grep -vE "^join-reorder$" |
    # ambiguous error
    grep -vE "^group_by$" |

    awk 'BEGIN{RS=EOF} {gsub(/\n/," "); print}'
`

# run test
echo "run test cases with whitelist: ${whitelist}"
./mysql_test --record=true --xunitfile ${CURRENT_PATH}/result.xml --port=6033 --record=true --log-level=error ${whitelist}