#!/bin/bash
#
# Environment configuration for keycloak

# The values for all environment variables will be set in the below order of precedence
# 1. Custom environment variables defined below after Bitnami defaults
# 2. Constants defined in this file (environment variables with no default), i.e. BITNAMI_ROOT_DIR
# 3. Environment variables overridden via external files using *_FILE variables (see below)
# 4. Environment variables set externally (i.e. current Bash context/Dockerfile/userdata)

# Load logging library
# shellcheck disable=SC1090,SC1091
. /opt/bitnami/scripts/liblog.sh

export BITNAMI_ROOT_DIR="/opt/bitnami"
export BITNAMI_VOLUME_DIR="/bitnami"

# Logging configuration
export MODULE="${MODULE:-keycloak}"
export BITNAMI_DEBUG="${BITNAMI_DEBUG:-false}"

# By setting an environment variable matching *_FILE to a file path, the prefixed environment
# variable will be overridden with the value specified in that file
keycloak_env_vars=(
    KEYCLOAK_MOUNTED_CONF_DIR
    KEYCLOAK_ADMIN
    KEYCLOAK_ADMIN_PASSWORD
    KEYCLOAK_HTTP_PORT
    KEYCLOAK_HTTPS_PORT
    KEYCLOAK_BIND_ADDRESS
    KEYCLOAK_FRONTEND_URL
    KEYCLOAK_INIT_MAX_RETRIES
    KEYCLOAK_CACHE_TYPE
    KEYCLOAK_EXTRA_ARGS
    KEYCLOAK_ENABLE_STATISTICS
    KEYCLOAK_ENABLE_TLS
    KEYCLOAK_TLS_TRUSTSTORE_FILE
    KEYCLOAK_TLS_TRUSTSTORE_PASSWORD
    KEYCLOAK_TLS_KEYSTORE_FILE
    KEYCLOAK_TLS_KEYSTORE_PASSWORD
    KEYCLOAK_LOG_LEVEL
    KEYCLOAK_ROOT_LOG_LEVEL
    KEYCLOAK_PROXY
    KEYCLOAK_CREATE_ADMIN_USER
    KEYCLOAK_PRODUCTION
    KEYCLOAK_DATABASE_HOST
    KEYCLOAK_DATABASE_PORT
    KEYCLOAK_DATABASE_USER
    KEYCLOAK_DATABASE_NAME
    KEYCLOAK_DATABASE_PASSWORD
    KEYCLOAK_DATABASE_SCHEMA
    KEYCLOAK_JDBC_PARAMS
    KEYCLOAK_DAEMON_USER
    KEYCLOAK_DAEMON_GROUP
    KEYCLOAK_ADMIN_USER
    KEYCLOAK_ADMIN_PASSWORD
    DB_ADDR
    DB_PORT
    DB_USER
    DB_DATABASE
    DB_PASSWORD
    DB_SCHEMA
    JDBC_PARAMS
)
for env_var in "${keycloak_env_vars[@]}"; do
    file_env_var="${env_var}_FILE"
    if [[ -n "${!file_env_var:-}" ]]; then
        if [[ -r "${!file_env_var:-}" ]]; then
            export "${env_var}=$(< "${!file_env_var}")"
            unset "${file_env_var}"
        else
            warn "Skipping export of '${env_var}'. '${!file_env_var:-}' is not readable."
        fi
    fi
done
unset keycloak_env_vars

# Paths
export BITNAMI_VOLUME_DIR="/bitnami"
export JAVA_HOME="/opt/bitnami/java"
export KEYCLOAK_BASE_DIR="/opt/bitnami/keycloak"
export KEYCLOAK_BIN_DIR="$KEYCLOAK_BASE_DIR/bin"
export KEYCLOAK_PROVIDERS_DIR="$KEYCLOAK_BASE_DIR/providers"
export KEYCLOAK_LOG_DIR="$KEYCLOAK_PROVIDERS_DIR/log"
export KEYCLOAK_TMP_DIR="$KEYCLOAK_PROVIDERS_DIR/tmp"
export KEYCLOAK_DOMAIN_TMP_DIR="$KEYCLOAK_BASE_DIR/domain/tmp"
export WILDFLY_BASE_DIR="/opt/bitnami/wildfly"
export KEYCLOAK_VOLUME_DIR="/bitnami/keycloak"
export KEYCLOAK_CONF_DIR="$KEYCLOAK_BASE_DIR/conf"
export KEYCLOAK_MOUNTED_CONF_DIR="${KEYCLOAK_MOUNTED_CONF_DIR:-${KEYCLOAK_VOLUME_DIR}/conf}"
export KEYCLOAK_INITSCRIPTS_DIR="/docker-entrypoint-initdb.d"
export KEYCLOAK_CONF_FILE="keycloak.conf"
export KEYCLOAK_DEFAULT_CONF_FILE="keycloak.conf"

# Keycloak configuration
KEYCLOAK_ADMIN="${KEYCLOAK_ADMIN:-"${KEYCLOAK_ADMIN_USER:-}"}"
export KEYCLOAK_ADMIN="${KEYCLOAK_ADMIN:-user}"
KEYCLOAK_ADMIN_PASSWORD="${KEYCLOAK_ADMIN_PASSWORD:-"${KEYCLOAK_ADMIN_PASSWORD:-}"}"
export KEYCLOAK_ADMIN_PASSWORD="${KEYCLOAK_ADMIN_PASSWORD:-bitnami}"
export KEYCLOAK_HTTP_PORT="${KEYCLOAK_HTTP_PORT:-8080}"
export KEYCLOAK_HTTPS_PORT="${KEYCLOAK_HTTPS_PORT:-8443}"
export KEYCLOAK_BIND_ADDRESS="${KEYCLOAK_BIND_ADDRESS:-$(hostname --fqdn)}"
export KEYCLOAK_FRONTEND_URL="${KEYCLOAK_FRONTEND_URL:-}"
export KEYCLOAK_INIT_MAX_RETRIES="${KEYCLOAK_INIT_MAX_RETRIES:-10}"
export KEYCLOAK_CACHE_TYPE="${KEYCLOAK_CACHE_TYPE:-ispn}"
export KEYCLOAK_EXTRA_ARGS="${KEYCLOAK_EXTRA_ARGS:-}"
export KEYCLOAK_ENABLE_STATISTICS="${KEYCLOAK_ENABLE_STATISTICS:-false}"
export KEYCLOAK_ENABLE_TLS="${KEYCLOAK_ENABLE_TLS:-false}"
export KEYCLOAK_TLS_TRUSTSTORE_FILE="${KEYCLOAK_TLS_TRUSTSTORE_FILE:-}"
export KEYCLOAK_TLS_TRUSTSTORE_PASSWORD="${KEYCLOAK_TLS_TRUSTSTORE_PASSWORD:-}"
export KEYCLOAK_TLS_KEYSTORE_FILE="${KEYCLOAK_TLS_KEYSTORE_FILE:-}"
export KEYCLOAK_TLS_KEYSTORE_PASSWORD="${KEYCLOAK_TLS_KEYSTORE_PASSWORD:-}"
export KEYCLOAK_LOG_LEVEL="${KEYCLOAK_LOG_LEVEL:-INFO}"
export KEYCLOAK_ROOT_LOG_LEVEL="${KEYCLOAK_ROOT_LOG_LEVEL:-INFO}"
export KEYCLOAK_PROXY="${KEYCLOAK_PROXY:-passthrough}"
export KEYCLOAK_CREATE_ADMIN_USER="${KEYCLOAK_CREATE_ADMIN_USER:-true}"
export KEYCLOAK_PRODUCTION="${KEYCLOAK_PRODUCTION:-false}"
KEYCLOAK_DATABASE_HOST="${KEYCLOAK_DATABASE_HOST:-"${DB_ADDR:-}"}"
export KEYCLOAK_DATABASE_HOST="${KEYCLOAK_DATABASE_HOST:-postgresql}"
KEYCLOAK_DATABASE_PORT="${KEYCLOAK_DATABASE_PORT:-"${DB_PORT:-}"}"
export KEYCLOAK_DATABASE_PORT="${KEYCLOAK_DATABASE_PORT:-5432}"
KEYCLOAK_DATABASE_USER="${KEYCLOAK_DATABASE_USER:-"${DB_USER:-}"}"
export KEYCLOAK_DATABASE_USER="${KEYCLOAK_DATABASE_USER:-bn_keycloak}"
KEYCLOAK_DATABASE_NAME="${KEYCLOAK_DATABASE_NAME:-"${DB_DATABASE:-}"}"
export KEYCLOAK_DATABASE_NAME="${KEYCLOAK_DATABASE_NAME:-bitnami_keycloak}"
KEYCLOAK_DATABASE_PASSWORD="${KEYCLOAK_DATABASE_PASSWORD:-"${DB_PASSWORD:-}"}"
export KEYCLOAK_DATABASE_PASSWORD="${KEYCLOAK_DATABASE_PASSWORD:-}"
KEYCLOAK_DATABASE_SCHEMA="${KEYCLOAK_DATABASE_SCHEMA:-"${DB_SCHEMA:-}"}"
export KEYCLOAK_DATABASE_SCHEMA="${KEYCLOAK_DATABASE_SCHEMA:-public}"
KEYCLOAK_JDBC_PARAMS="${KEYCLOAK_JDBC_PARAMS:-"${JDBC_PARAMS:-}"}"
export KEYCLOAK_JDBC_PARAMS="${KEYCLOAK_JDBC_PARAMS:-}"

# System users (when running with a privileged user)
export KEYCLOAK_DAEMON_USER="${KEYCLOAK_DAEMON_USER:-keycloak}"
export KEYCLOAK_DAEMON_GROUP="${KEYCLOAK_DAEMON_GROUP:-keycloak}"

# Custom environment variables may be defined below
