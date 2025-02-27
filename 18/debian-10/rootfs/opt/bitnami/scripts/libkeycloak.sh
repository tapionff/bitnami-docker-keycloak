#!/bin/bash
#
# Bitnami Keycloak library

# shellcheck disable=SC1090,SC1091

# Load Generic Libraries
. /opt/bitnami/scripts/libfs.sh
. /opt/bitnami/scripts/liblog.sh
. /opt/bitnami/scripts/libnet.sh
. /opt/bitnami/scripts/libos.sh
. /opt/bitnami/scripts/libfile.sh
. /opt/bitnami/scripts/libvalidations.sh

########################
# Validate settings in KEYCLOAK_* env. variables
# Globals:
#   KEYCLOAK_*
# Arguments:
#   None
# Returns:
#   None
#########################
keycloak_validate() {
    info "Validating settings in KEYCLOAK_* env vars..."
    local error_code=0

    # Auxiliary functions
    print_validation_error() {
        error "$1"
        error_code=1
    }

    check_allowed_port() {
        local port_var="${1:?missing port variable}"
        local -a validate_port_args=()
        ! am_i_root && validate_port_args+=("-unprivileged")
        validate_port_args+=("${!port_var}")
        if ! err=$(validate_port "${validate_port_args[@]}"); then
            print_validation_error "An invalid port was specified in the environment variable ${port_var}: ${err}."
        fi
    }
    if is_boolean_yes "$KEYCLOAK_PRODUCTION"; then
        if ! is_boolean_yes "$KEYCLOAK_ENABLE_TLS"; then
            print_validation_error "You need to have the TLS enable. Please set the KEYCLOAK_ENABLE_TLS variable to true"
        fi
    fi

    if is_boolean_yes "$KEYCLOAK_ENABLE_TLS"; then
        if is_empty_value "$KEYCLOAK_TLS_TRUSTSTORE_FILE"; then
            print_validation_error "Path to the TLS truststore file not defined. Please set the KEYCLOAK_TLS_TRUSTSTORE_FILE variable to the mounted truststore"
        fi
        if is_empty_value "$KEYCLOAK_TLS_KEYSTORE_FILE"; then
            print_validation_error "Path to the TLS keystore file not defined. Please set the KEYCLOAK_TLS_KEYSTORE_FILE variable to the mounted keystore"
        fi
    fi

    if ! validate_ipv4 "${KEYCLOAK_BIND_ADDRESS}"; then
        if ! is_hostname_resolved "${KEYCLOAK_BIND_ADDRESS}"; then
            print_validation_error print_validation_error "The value for KEYCLOAK_BIND_ADDRESS ($KEYCLOAK_BIND_ADDRESS) should be an IPv4 address or it must be a resolvable hostname"
        fi
    fi

    if [[ "$KEYCLOAK_HTTP_PORT" -eq "$KEYCLOAK_HTTPS_PORT" ]]; then
        print_validation_error "KEYCLOAK_HTTP_PORT and KEYCLOAK_HTTPS_PORT are bound to the same port!"
    fi
    check_allowed_port KEYCLOAK_HTTP_PORT
    check_allowed_port KEYCLOAK_HTTPS_PORT

    for var in KEYCLOAK_CREATE_ADMIN_USER KEYCLOAK_ENABLE_TLS KEYCLOAK_ENABLE_STATISTICS; do
        if ! is_true_false_value "${!var}"; then
            print_validation_error "The allowed values for $var are [true, false]"
        fi
    done

    [[ "$error_code" -eq 0 ]] || exit "$error_code"
}

########################
# Add or modify an entry in the Discourse configuration file
# Globals:
#   KEYCLOAK_*
# Arguments:
#   $1 - Variable name
#   $2 - Value to assign to the variable
# Returns:
#   None
#########################
keycloak_conf_set() {
    local -r key="${1:?key missing}"
    local -r value="${2:-}"
    debug "Setting ${key} to '${value}' in Keycloak configuration"
    # Sanitize key (sed does not support fixed string substitutions)
    local sanitized_pattern
    sanitized_pattern="^\s*(#\s*)?$(sed 's/[]\[^$.*/]/\\&/g' <<< "$key")\s*=\s*(.*)"
    local entry="${key} = ${value}"
    # Check if the configuration exists in the file
    if grep -q -E "$sanitized_pattern" "${KEYCLOAK_CONF_DIR}/${KEYCLOAK_CONF_FILE}"; then
        # It exists, so replace the line
        replace_in_file "${KEYCLOAK_CONF_DIR}/${KEYCLOAK_CONF_FILE}" "$sanitized_pattern" "$entry"
    else
        echo "$entry" >> "${KEYCLOAK_CONF_DIR}/${KEYCLOAK_CONF_FILE}"
    fi
}

########################
# Configure database settings
# Globals:
#   KEYCLOAK_*
# Arguments:
#   None
# Returns:
#   None
#########################
keycloak_configure_database() {
    info "Configuring database settings"
    keycloak_conf_set "db" "postgres"
    keycloak_conf_set "db-username" "$KEYCLOAK_DATABASE_USER"
    keycloak_conf_set "db-password" "$KEYCLOAK_DATABASE_PASSWORD"
    keycloak_conf_set "db-url" "jdbc:postgresql://${KEYCLOAK_DATABASE_HOST}:${KEYCLOAK_DATABASE_PORT}/${KEYCLOAK_DATABASE_NAME}?currentSchema=${KEYCLOAK_DATABASE_SCHEMA:-public}"
    debug_execute kc.sh build --db postgres
}

########################
# Configure cluster caching
# Globals:
#   KEYCLOAK_*
# Arguments:
#   None
# Returns:
#   None
#########################
keycloak_configure_cache() {
    info "Configuring cache count"
    keycloak_conf_set "cache" "$KEYCLOAK_CACHE_TYPE"
}

########################
# Enable statistics
# Globals:
#   KEYCLOAK_*
# Arguments:
#   None
# Returns:
#   None
#########################
keycloak_configure_metrics() {
    info "Enabling statistics"
    keycloak_conf_set "metrics-enabled" "$KEYCLOAK_ENABLE_STATISTICS"
}

########################
# Configure hostname 
# Globals:
#   KEYCLOAK_*
# Arguments:
#   None
# Returns:
#   None
#########################
keycloak_configure_hostname(){
    info "Configuring hostname settings"
    keycloak_conf_set "hostname-strict" "false"
}

########################
# Configure http 
# Globals:
#   KEYCLOAK_*
# Arguments:
#   None
# Returns:
#   None
#########################
keycloak_configure_http(){
    info "Configuring http settings"
    keycloak_conf_set "http-enabled" "true"
    keycloak_conf_set "https-stric" "false"
    keycloak_conf_set "http-port" "${KEYCLOAK_HTTP_PORT}"
    keycloak_conf_set "https-port" "${KEYCLOAK_HTTPS_PORT}"
}

########################
# Configure logging settings
# Globals:
#   KEYCLOAK_*
# Arguments:
#   None
# Returns:
#   None
#########################
keycloak_configure_loglevel() {
    info "Configuring log level"
    keycloak_conf_set "log-level" "${KEYCLOAK_LOG_LEVEL}"
}

########################
# Configure proxy settings using JBoss CLI
# Globals:
#   KEYCLOAK_*
# Arguments:
#   None
# Returns:
#   None
#########################
keycloak_configure_proxy() {
    info "Configuring proxy"
    keycloak_conf_set "proxy" "${KEYCLOAK_PROXY}"
}

 ########################
# Configure database settings
# Globals:
#   KEYCLOAK_*
# Arguments:
# Returns:
#   None
#########################
keycloak_configure_tls() {
    info "Configuring TLS by setting keystore and truststore"
    keycloak_conf_set "https-key-store-file" "${KEYCLOAK_TLS_KEYSTORE_FILE}"
    keycloak_conf_set "https-trust-store-file" "${KEYCLOAK_TLS_TRUSTSTORE_FILE}"
    ! is_empty_value "$KEYCLOAK_TLS_KEYSTORE_PASSWORD" && keycloak_conf_set "https-key-store-password" "${KEYCLOAK_TLS_KEYSTORE_PASSWORD}"
    ! is_empty_value "$KEYCLOAK_TLS_TRUSTSTORE_PASSWORD" && keycloak_conf_set "https-trust-store-password" "${KEYCLOAK_TLS_TRUSTSTORE_PASSWORD}"
}

########################
# Initialize keycloak installation
# Globals:
#   KEYCLOAK_*
# Arguments:
#   None
# Returns:
#   None
#########################
keycloak_initialize() {
    # Clean to avoid issues when running docker restart
    # Wait for database
    info "Trying to connect to PostgreSQL server $KEYCLOAK_DATABASE_HOST..."
    if ! retry_while "wait-for-port --host $KEYCLOAK_DATABASE_HOST --timeout 10 $KEYCLOAK_DATABASE_PORT" "$KEYCLOAK_INIT_MAX_RETRIES"; then
        error "Unable to connect to host $KEYCLOAK_DATABASE_HOST"
        exit 1
    else
        info "Found PostgreSQL server listening at $KEYCLOAK_DATABASE_HOST:$KEYCLOAK_DATABASE_PORT"
    fi

    if ! is_dir_empty "$KEYCLOAK_MOUNTED_CONF_DIR"; then
        cp -Lr "$KEYCLOAK_MOUNTED_CONF_DIR"/* "$KEYCLOAK_CONF_DIR"
    fi
    keycloak_configure_database
    keycloak_configure_metrics
    keycloak_configure_http
    keycloak_configure_hostname
    keycloak_configure_cache
    keycloak_configure_loglevel
    keycloak_configure_proxy
    is_boolean_yes "$KEYCLOAK_ENABLE_TLS" && keycloak_configure_tls
    true
}

########################
# Run custom initialization scripts
# Globals:
#   KEYCLOAK_*
# Arguments:
#   None
# Returns:
#   None
#########################
keycloak_custom_init_scripts() {
    if [[ -n $(find "${KEYCLOAK_INITSCRIPTS_DIR}/" -type f -regex ".*\.sh") ]] && [[ ! -f "${KEYCLOAK_INITSCRIPTS_DIR}/.user_scripts_initialized" ]]; then
        info "Loading user's custom files from ${KEYCLOAK_INITSCRIPTS_DIR} ..."
        local -r tmp_file="/tmp/filelist"
        find "${KEYCLOAK_INITSCRIPTS_DIR}/" -type f -regex ".*\.sh" | sort >"$tmp_file"
        while read -r f; do
            case "$f" in
            *.sh)
                if [[ -x "$f" ]]; then
                    debug "Executing $f"
                    "$f"
                else
                    debug "Sourcing $f"
                    . "$f"
                fi
                ;;
            *) debug "Ignoring $f" ;;
            esac
        done <$tmp_file
        rm -f "$tmp_file"
        touch "$KEYCLOAK_VOLUME_DIR"/.user_scripts_initialized
    fi
}
