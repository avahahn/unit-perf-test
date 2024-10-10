#!/bin/sh
unitd --control 127.0.0.1:8080 --no-daemon 2>/dev/null &
UNIT_BG_PID=$!
sleep 3

alias curl="curl -v --fail"
alias wrk="/wrk/wrk -t22 -c880 -d30s"
chmod "+x" /wrk/wrk
echo "initial configuration"

curl -X PUT 127.0.0.1:8080/config -d '{
    "listeners": {
        "*:80": {
            "pass": "routes"
        }
    },
    "routes": [
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
    ]
}'

sleep 3
echo "sleeping for 60s to wait for grafana to rise"
sleep 60

echo "configuring tracer"

curl -X PUT 127.0.0.1:8080/config -d '{
    "settings": {
        "telemetry": {
            "batch_size": 20,
            "endpoint": "http://lgtm:4318/v1/traces",
            "protocol": "http",
            "sampling_ratio": 1
        }
    },
    "listeners": {
        "*:80": {
            "pass": "routes"
        }
    },
    "routes": [
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
    ]
}'

wrk http://127.0.0.1:80/
echo "configuring none tracer"

curl -X DELETE 127.0.0.1:8080/config/settings/telemetry
wrk http://127.0.0.1:80/

echo "killing unit, starting stock unit"
kill -9 $UNIT_BG_PID
sleep 3

unit-clean --control 127.0.0.1:8080 2>/dev/null
sleep 3

echo "clean configuration"

curl -X PUT 127.0.0.1:8080/config -d '{
    "listeners": {
        "*:80": {
            "pass": "routes"
        }
    },
    "routes": [
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
    ]
}'

sleep 3
wrk http://127.0.0.1:80/

