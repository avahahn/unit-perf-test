#!/bin/sh
set -ex

unitd --control 127.0.0.1:8080
sleep 3

echo "initial configuration"

curl -X PUT 127.0.0.1/routes -d '[
    {
        "match": {
            "headers": {
                "accept": "*text/html*"
            }
        },
        "action": {
            "share": "/usr/share/unit/welcome/welcome.html"
        }
    },
    {
        "action": {
            "share": "/usr/share/unit/welcome/welcome.md"
        }
    }
]'


curl -X PUT 127.0.0.1/listeners -d '{
    "*:80": {
        "pass": "routes"
    }
}'

if [ ! curl 127.0.0.1 ]; then
    echo "failed initial curl"
    exit 1 
fi

echo "configuring tracer"

curl -X PUT 127.0.0.1/settings/telemetry -d '{
    "batch_size": 10,
    "endpoint": "http://lgtm:4318/v1/traces",
    "protocol": "http"
}'

if [ ! curl 127.0.0.1 ]; then 
    echo "failed curl with telemetry enabled"
    exit 1
fi

wrk -t22 -c880 -d30s http://127.0.0.1/

echo "configuring none tracer"

curl -X PUT 127.0.0.1/settings/telemetry -d '{}'

if [ ! curl 127.0.0.1 ]; then 
    echo "failed curl with non telemetry"
    exit 1 
fi 

wrk -t22 -c880 -d30s http://127.0.0.1/


