#!/bin/bash
set -e

# Perform all actions as $POSTGRES_USER
export PGUSER="$POSTGRES_USER"

# sed -i 's/\(peer\|md5\)/trust/' /etc/postgresql/10/main/pg_hba.conf
{
        echo
        echo "local all $PGUSER     trust"
        echo "local all all         trust"
        echo "host  all all     all trust"
} >> "$PGDATA/pg_hba.conf"

pg_ctl reload

psql -U "$POSTGRES_USER" -Atc "SELECT pg_reload_conf();"

echo "Creating user 'publicuser'..."
createuser publicuser --no-createrole --no-createdb --no-superuser -U $PGUSER
echo "Creating user 'tileuser'..."
createuser tileuser --no-createrole --no-createdb --no-superuser -U $PGUSER

# Initialize template_postgis database. We create a template database in postgresql that will
# contain the postgis extension. This way, every time CartoDB creates a new user database it just
# clones this template database
echo "Creating database 'template_postgis'..."
createdb -T template0 -O $PGUSER -U $PGUSER -E UTF8 template_postgis
echo "Creating extensions 'postgis' and 'postgis_topology' on database 'template_postgis'..."
psql -U $PGUSER template_postgis -c 'CREATE EXTENSION postgis;CREATE EXTENSION postgis_topology;'

for ext in postgis plpythonu cartodb postgis_topology fuzzystrmatch postgis_tiger_geocoder uuid-ossp; do
  psql -U "$POSTGRES_USER" "$POSTGRES_DB" -Atc "create extension if not exists \"${ext}\" ;";
done
ldconfig

