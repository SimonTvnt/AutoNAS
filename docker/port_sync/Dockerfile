FROM alpine:3.18

# Create non-root user
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Install required packages with specific versions
RUN apk add --no-cache \
    curl=8.12.1-r0 \
    bash=5.2.15-r5 \
    jq=1.6-r4

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