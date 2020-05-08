#!/bin/bash

echo "start kafka connect"

if [[ -z "$CONNECT_BOOTSTRAP_SERVERS" ]]; then
    echo "ERROR: missing mandatory config: $CONNECT_BOOTSTRAP_SERVERS"
    exit 1
fi
echo "bootstrap.servers = $KAFKA_BOOTSTRAP_SERVERS"

(
    function updateConfig() {
        key=$1
        value=$2
        file=$3

        # Omit $value here, in case there is sensitive information
        echo "[Configuring] '$key' in '$file'"

        if grep -E -q "^#?$key=" "$file"; then
            sed -r -i "s@^#?$key=.*@$key=$value@g" "$file" #note that no config values may contain an '@' char
        else
            echo "$key=$value" >> "$file"
        fi
    }

    for VAR in $(env); do
        env_var=$(echo "$VAR" | cut -d= -f1)
        if [[ ${env_var} =~ ^CONNECT_ ]]; then
            kafka_name=$(echo "$env_var" | cut -d_ -f2- | tr '[:upper:]' '[:lower:]' | tr _ .)
            echo "key: $kafka_name, value: ${!env_var}"
            updateConfig "$kafka_name" "${!env_var}" "${KAFKA_HOME}/config/connect-distributed.properties"
        fi
    done
)

echo "end start-connect.sh"

exec "${KAFKA_HOME}/bin/connect-distributed.sh" "${KAFKA_HOME}/config/connect-distributed.properties"