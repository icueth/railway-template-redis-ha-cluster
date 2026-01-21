FROM redis:7.4-alpine

# Install required tools
RUN apk add --no-cache bash gettext

# Copy configuration and scripts
COPY redis.conf /etc/redis/redis.conf.template
COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

EXPOSE 6379

ENTRYPOINT ["/entrypoint.sh"]
