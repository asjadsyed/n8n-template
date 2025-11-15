FROM docker.n8n.io/n8nio/n8n:1.113.3 AS base

FROM base AS n8n

FROM base AS n8n-init

USER root
RUN apk add --no-cache curl jq bash ca-certificates

USER node
COPY ./n8n-data/workflows/ /opt/n8n/workflows/
COPY ./n8n-init.sh .
ENTRYPOINT [ "./n8n-init.sh" ]
