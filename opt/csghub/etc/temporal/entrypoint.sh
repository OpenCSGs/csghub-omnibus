#!/bin/bash

set -eu -o pipefail

: "${TEMPORAL_HOME:=/etc/temporal}"
export TEMPORAL_HOME

: "${BIND_ON_IP:=$(getent hosts "$(hostname)" | awk '{print $1;}')}"
export BIND_ON_IP

if [[ "${BIND_ON_IP}" == "0.0.0.0" ]]; then
    : "${TEMPORAL_BROADCAST_ADDRESS:=$(getent hosts "$(hostname)" | awk '{print $1;}')}"
    export TEMPORAL_BROADCAST_ADDRESS
fi

# check TEMPORAL_ADDRESS is not empty
if [[ -z "${TEMPORAL_ADDRESS:-}" ]]; then
    echo "TEMPORAL_ADDRESS is not set, setting it to ${BIND_ON_IP}:7233"

    if [[ "${BIND_ON_IP}" =~ ":" ]]; then
        # ipv6
        export TEMPORAL_ADDRESS="[${BIND_ON_IP}]:7233"
    else
        # ipv4
        export TEMPORAL_ADDRESS="${BIND_ON_IP}:7233"
    fi
fi

# Support TEMPORAL_CLI_ADDRESS for backwards compatibility.
# TEMPORAL_CLI_ADDRESS is deprecated and support for it will be removed in the future release.
if [[ -z "${TEMPOAL_CLI_ADDRESS:-}" ]]; then
    export TEMPORAL_CLI_ADDRESS="${TEMPORAL_ADDRESS}"
fi

dockerize -template "${TEMPORAL_HOME}"/config/config_template.yaml:"${TEMPORAL_HOME}"/config/docker.yaml

# Automatically setup Temporal Server (databases, Elasticsearch, default namespace) if "autosetup" is passed as an argument.
for arg; do
    if [[ ${arg} == autosetup ]]; then
        "${TEMPORAL_HOME}"/auto-setup.sh
        break
    fi
done

# Setup Temporal Server in development mode if "develop" is passed as an argument.
for arg; do
    if [[ ${arg} == develop ]]; then
        "${TEMPORAL_HOME}"/setup-develop.sh
        break
    fi
done

# Run bash instead of Temporal Server if "bash" is passed as an argument (convenient to debug docker image).
for arg; do
    if [[ ${arg} == bash ]]; then
        bash
        exit 0
    fi
done

exec "${TEMPORAL_HOME}"/start-temporal.sh