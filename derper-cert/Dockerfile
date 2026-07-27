FROM alpine:3.23.5
RUN apk add --no-cache tini ca-certificates inotify-tools docker-cli
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/sbin/tini", "-g", "--", "/entrypoint.sh"]
