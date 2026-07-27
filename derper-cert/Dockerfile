FROM alpine:3.23.5
RUN apk add --no-cache ca-certificates inotify-tools docker-cli
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
