FROM redis:7.4-alpine

# Install required tools
RUN apk add --no-cache bash gettext

# Copy configuration and scripts
COPY sentinel.conf /etc/redis/sentinel.conf.template
COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

EXPOSE 26379

ENTRYPOINT ["/entrypoint.sh"]
