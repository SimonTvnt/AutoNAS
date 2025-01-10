FROM base AS builder

FROM alpine:latest
RUN apk --no-cache add libc6-compat

WORKDIR /exporter
COPY --from=builder /bin/qbittorrent_port .

# Command to run the application
CMD ["./qbittorrent_port"]
