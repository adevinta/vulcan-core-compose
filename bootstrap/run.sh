#!/bin/sh

# Copyright 2020 Adevinta

export PG_PORT=${PG_PORT:-5432}
export PG_HOST=${PG_HOST:-postgres}
export PERSISTENCE_HOST=${PERSISTENCE_HOST:-persistence}
export PERSISTENCE_PORT=${PERSISTENCE_PORT:-80}

echo "Start - Bootstrap"

until pg_isready -h $PG_HOST -p $PG_PORT -t 10; do
    sleep 1 && echo "Waiting for postgres";
done

until nc $PERSISTENCE_HOST $PERSISTENCE_PORT; do
    sleep 1 && echo "Waiting for vulcan-persistence";
done

STATUS_CODE=$(curl -s -o /dev/null -I -w "%{http_code}" "http://${PERSISTENCE_HOST}/v1/jobqueues/00000000-0000-0000-0000-000000000000")
if [ $STATUS_CODE -ne 200 ]; then
    curl -s -H "Content-type: application/json" "http://${PERSISTENCE_HOST}/v1/jobqueues" -d@jobqueues/generic.json | jq
    psql -h $PG_HOST -U $PG_USER $PG_DB -c "update jobqueues set id='00000000-0000-0000-0000-000000000000' where name='VulcanK8SChecksGeneric'"
fi

for check in $(ls checks); do
    curl -s -H "Content-type: application/json" "http://${PERSISTENCE_HOST}/v1/checktypes" -d@checks/${check} | jq
done

echo "Finish - Bootstrap"
