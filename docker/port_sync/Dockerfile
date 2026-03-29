FROM alpine:3.21

# Create non-root user
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Install required packages
# Note: version pins removed for Alpine 3.21 compatibility — re-pin after verifying
# available versions with: docker run --rm alpine:3.21 apk info curl bash jq
RUN apk add --no-cache \
    curl \
    bash \
    jq

WORKDIR /rpi_scripts

# Copy script and set proper permissions
COPY scripts/update_qtorrent_port.sh /update.sh
RUN chmod +x /update.sh && \
    chown appuser:appgroup /update.sh

# Switch to non-root user
USER appuser

# Add healthcheck
HEALTHCHECK --interval=60s --timeout=3s \
    CMD pgrep -f "update.sh" || exit 1

CMD ["/update.sh"]
