#!/bin/bash
#
# Temporal database schema setup and default namespace bootstrap.
#
# Runs on the omnibus host before `temporal-server` starts:
#   - creates the temporal/visibility databases and applies the versioned
#     PostgreSQL schema via temporal-sql-tool
#   - once the server is serving, registers the default namespace and its
#     search attributes via the temporal CLI
#
# Both tools come from the temporalio/admin-tools image; temporal-server comes
# from the temporalio/server image. Connection details and
# DEFAULT_NAMESPACE_RETENTION are written to the service envdir by the temporal
# pre-start hook in csghub-ctl.

set -eu -o pipefail

: "${TEMPORAL_HOME:=/opt/csghub/embedded/etc/temporal}"
: "${POSTGRES_SCHEMA_VERSION_DIR:=v12}"

# PostgreSQL
: "${DBNAME:=csghub_temporal}"
: "${VISIBILITY_DBNAME:=${DBNAME}_visibility}"
: "${POSTGRES_SEEDS:=127.0.0.1}"
: "${DB_PORT:=5432}"
: "${POSTGRES_USER:=csghub}"
: "${POSTGRES_PWD:=}"

# Server bootstrap
: "${TEMPORAL_ADDRESS:=127.0.0.1:7233}"
: "${DEFAULT_NAMESPACE:=default}"
: "${DEFAULT_NAMESPACE_RETENTION:=7d}"

: "${SKIP_SCHEMA_SETUP:=false}"
: "${SKIP_DEFAULT_NAMESPACE_CREATION:=false}"
: "${SKIP_ADD_CUSTOM_SEARCH_ATTRIBUTES:=false}"

# Only the first host of a comma-separated seed list is used; the omnibus
# deployment always talks to a single local PostgreSQL.
POSTGRES_HOST="${POSTGRES_SEEDS%%,*}"
SCHEMA_DIR="${TEMPORAL_HOME}/schema/postgresql/${POSTGRES_SCHEMA_VERSION_DIR}"

# temporal-sql-tool reads the password from the environment.
export SQL_PASSWORD="${POSTGRES_PWD}"

sql_tool() {
    local db="$1"; shift
    temporal-sql-tool \
        --plugin postgres12 \
        --ep "${POSTGRES_HOST}" \
        -u "${POSTGRES_USER}" \
        -p "${DB_PORT}" \
        --db "${db}" \
        "$@"
}

wait_for_postgres() {
    until nc -z "${POSTGRES_HOST}" "${DB_PORT}"; do
        echo "Waiting for PostgreSQL to start up."
        sleep 1
    done
    echo "PostgreSQL started."
}

setup_store() {
    local db="$1" schema="$2"

    echo "Setting up ${db} schema."
    # Idempotent, but tolerated as a failure so that a database provisioned
    # out-of-band (csghub-dbm, or an existing deployment) is not fatal.
    sql_tool "${db}" create-database || true
    sql_tool "${db}" setup-schema -v 0.0
    sql_tool "${db}" update-schema --schema-dir "${SCHEMA_DIR}/${schema}/versioned"
}

setup_schema() {
    setup_store "${DBNAME}" temporal
    setup_store "${VISIBILITY_DBNAME}" visibility
}

register_default_namespace() {
    if temporal operator namespace describe --namespace "${DEFAULT_NAMESPACE}" >/dev/null 2>&1; then
        echo "Default namespace ${DEFAULT_NAMESPACE} already registered."
        return
    fi

    echo "Registering default namespace ${DEFAULT_NAMESPACE}."
    temporal operator namespace create \
        --namespace "${DEFAULT_NAMESPACE}" \
        --retention "${DEFAULT_NAMESPACE_RETENTION}" \
        --description "Default namespace for Temporal Server."
}

add_custom_search_attributes() {
    until temporal operator search-attribute list --namespace "${DEFAULT_NAMESPACE}" >/dev/null 2>&1; do
        echo "Waiting for namespace cache to refresh..."
        sleep 1
    done

    temporal operator search-attribute create --namespace "${DEFAULT_NAMESPACE}" \
        --name CustomKeywordField --type Keyword \
        --name CustomStringField --type Text \
        --name CustomTextField --type Text \
        --name CustomIntField --type Int \
        --name CustomDatetimeField --type Datetime \
        --name CustomDoubleField --type Double \
        --name CustomBoolField --type Bool
}

# Runs in the background: the runit run script execs temporal-server as soon as
# this script returns, so waiting here in the foreground would deadlock.
setup_server() {
    until temporal operator cluster health | grep -q SERVING; do
        echo "Waiting for Temporal server to start..."
        sleep 1
    done
    echo "Temporal server started."

    if [[ ${SKIP_DEFAULT_NAMESPACE_CREATION} != true ]]; then
        register_default_namespace
    fi

    if [[ ${SKIP_ADD_CUSTOM_SEARCH_ATTRIBUTES} != true ]]; then
        add_custom_search_attributes
    fi
}

if [[ ${SKIP_SCHEMA_SETUP} != true ]]; then
    if [[ -z ${POSTGRES_SEEDS} ]]; then
        echo "POSTGRES_SEEDS must be set" 1>&2
        exit 1
    fi
    wait_for_postgres
    setup_schema
fi

setup_server &
