#!/bin/bash

set -e
set -u

function create_user_and_database() {
	local database=$(echo $1 | tr ',' ' ' | awk  '{print $1}')
	local owner=$(echo $1 | tr ',' ' ' | awk  '{print $2}')
	echo "  Creating user and database '$database'"
	psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" <<-EOSQL
		DO
		\$do\$
	    BEGIN
			IF EXISTS (
				SELECT * FROM pg_catalog.pg_user
				WHERE pg_user.usename = '$owner'
			) THEN
				RAISE NOTICE 'Role $owner already exists, skipping creation';
			ELSE
				CREATE USER "$owner" LOGIN PASSWORD '$POSTGRES_PASSWORD';
			END IF;
		END
		\$do\$;
	    CREATE DATABASE "$database";
	    GRANT ALL ON DATABASE "$database" TO "$owner";
		ALTER DATABASE "$database" OWNER TO "$owner";
	EOSQL
}

if [ -n "$POSTGRES_MULTIPLE_DATABASES" ]; then
	echo "Multiple database creation requested: $POSTGRES_MULTIPLE_DATABASES"
	for db in $(echo $POSTGRES_MULTIPLE_DATABASES | tr ':' ' '); do
		create_user_and_database $db
	done
	echo "Multiple databases created"
fi
