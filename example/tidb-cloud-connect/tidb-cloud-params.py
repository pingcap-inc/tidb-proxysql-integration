PROXYSQL_CNF_FILENAME = 'tidb-cloud-connect.cnf.template'
PREPARE_SQL_FILENAME = 'proxysql-prepare.sql.template'
TEMPLATE_SUFFIX = '.template'

print("""You can use this script to format your config files.
Or just manually replace the
  <serverless tier host>
  <serverless tier username>
  <serverless tier password>
in proxysql-prepare.sql.template and tidb-cloud-connect.cnf.template
and save with name proxysql-prepare.sql and tidb-cloud-connect.cnf.
""")


def replace_file_params(template_filename, host, username, password):
    if not str.endswith(template_filename, TEMPLATE_SUFFIX):
        return

    with open(template_filename, mode='r') as template:
        content = template.read()
        content = content.replace('<serverless tier host>', host)
        content = content.replace('<serverless tier username>', username)
        content = content.replace('<serverless tier password>', password)

        config_filename = template_filename.replace(TEMPLATE_SUFFIX, "")
        with open(config_filename, mode='w') as config:
            config.write(content)


serverless_tier_host = input("Serverless Tier Host: ")
serverless_tier_username = input("Serverless Tier Username: ")
serverless_tier_password = input("Serverless Tier Password: ")

replace_file_params(PROXYSQL_CNF_FILENAME, serverless_tier_host, serverless_tier_username, serverless_tier_password)
replace_file_params(PREPARE_SQL_FILENAME, serverless_tier_host, serverless_tier_username, serverless_tier_password)
