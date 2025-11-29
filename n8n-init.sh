#!/bin/bash

set -euo pipefail

COOKIE_JAR="/tmp/cookies.txt"

until N8N_SETTINGS_RESPONSE=$(
    curl -fsS "http://n8n:5678/rest/settings"
); do
    echo "n8n not yet available; retrying in 5s..."
    sleep 5
done

owner_setup() {
    N8N_OWNER_SETUP_PAYLOAD=$(
        jq -n \
        --arg N8N_FIRST_NAME "$N8N_FIRST_NAME" \
        --arg N8N_LAST_NAME "$N8N_LAST_NAME" \
        --arg N8N_EMAIL "$N8N_EMAIL" \
        --arg N8N_PASSWORD "$N8N_PASSWORD" \
        '{
            "email":$N8N_EMAIL,"firstName":$N8N_FIRST_NAME,"lastName":$N8N_LAST_NAME,"password":$N8N_PASSWORD,"agree":true
        }'
    )
    N8N_OWNER_SETUP_RESPONSE=$(
        curl -fsS "http://n8n:5678/rest/owner/setup" \
        -c "$COOKIE_JAR" \
        -b "$COOKIE_JAR" \
        -X POST \
        -H "Content-Type: application/json" \
        --data-raw "$N8N_OWNER_SETUP_PAYLOAD"
    )
}

login() {
    LOGIN_PAYLOAD=$(
        jq -n \
        --arg N8N_EMAIL "$N8N_EMAIL" \
        --arg N8N_PASSWORD "$N8N_PASSWORD" \
        '{
            "emailOrLdapLoginId":$N8N_EMAIL,"password":$N8N_PASSWORD
        }'
    )
    LOGIN_RESPONSE=$(
        curl -fsS "http://n8n:5678/rest/login" \
        -c "$COOKIE_JAR" \
        -b "$COOKIE_JAR" \
        -X POST \
        -H "Content-Type: application/json" \
        --data-raw "$LOGIN_PAYLOAD"
    )
}

login || owner_setup

SURVEY_PAYLOAD='{"version":"v4","personalization_survey_submitted_at":"","personalization_survey_n8n_version":""}'
SURVEY_RESPONSE=$(
    curl -fsS "http://n8n:5678/rest/me/survey" \
    -c "$COOKIE_JAR" \
    -b "$COOKIE_JAR" \
    -X POST \
    -H 'Content-Type: application/json' \
    --data-raw "$SURVEY_PAYLOAD"
)

ensure_ollama_account_credentials() {
    EXISTING_ACCOUNT_CREDENTIALS_RESPONSE=$(
        curl -fsS "http://n8n:5678/rest/credentials" \
            -c "$COOKIE_JAR" \
            -b "$COOKIE_JAR"
    )

    OLLAMA_ACCOUNT_CREDENTIALS_ID=$(
        echo "$EXISTING_ACCOUNT_CREDENTIALS_RESPONSE" \
            | jq -r '.data[]?
                | select(.type == "ollamaApi" and .name == "Ollama account")
                | .id' \
            | head -n 1
    )

    if [ -z "$OLLAMA_ACCOUNT_CREDENTIALS_ID" ] || [ "$OLLAMA_ACCOUNT_CREDENTIALS_ID" = "null" ]; then
        OLLAMA_ACCOUNT_CREDENTIALS_PAYLOAD='{"name":"Ollama account","type":"ollamaApi","data":{"baseUrl":"http://ollama:11434"}}'
        OLLAMA_ACCOUNT_CREDENTIALS_RESPONSE=$(
            curl -fsS "http://n8n:5678/rest/credentials" \
            -c "$COOKIE_JAR" \
            -b "$COOKIE_JAR" \
            -X POST \
            -H 'Content-Type: application/json' \
            --data-raw "$OLLAMA_ACCOUNT_CREDENTIALS_PAYLOAD"
        )
    fi
}
ensure_ollama_account_credentials

n8n import:workflow --input /opt/n8n/workflows/ --separate

# CREATE_API_KEY_REQUEST='{"label":"Init","expiresAt":null,"scopes":["credential:create","credential:delete","credential:move","project:create","project:delete","project:list","project:update","securityAudit:generate","sourceControl:pull","tag:create","tag:delete","tag:list","tag:read","tag:update","user:changeRole","user:create","user:delete","user:enforceMfa","user:list","user:read","variable:create","variable:delete","variable:list","variable:update","workflow:create","workflow:delete","workflow:list","workflow:move","workflow:read","workflow:update","workflowTags:update","workflowTags:list","workflow:activate","workflow:deactivate","execution:delete","execution:read","execution:retry","execution:list"]}'
# CREATE_API_KEY_RESPONSE=$(
#     curl -fsS "http://n8n:5678/rest/api-keys" \
#     -X POST \
#     -c "$COOKIE_JAR" \
#     -b "$COOKIE_JAR" \
#     -H 'Content-Type: application/json' \
#     --data-raw "$CREATE_API_KEY_REQUEST"
# )

# N8N_INIT_API_KEY=$(echo "$CREATE_API_KEY_RESPONSE" | jq -r ".data.rawApiKey")
# N8N_INIT_API_KEY_ID=$(echo "$CREATE_API_KEY_RESPONSE" | jq -r ".data.id")

# DELETE_API_KEY_RESPONSE=$(
#     curl -fsS "http://n8n:5678/rest/api-keys/$N8N_INIT_API_KEY_ID" \
#     -X DELETE \
#     -c "$COOKIE_JAR" \
#     -b "$COOKIE_JAR"
# )

echo "Finished init"
