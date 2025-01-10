FROM base AS builder

FROM debian:bullseye AS debian
RUN apt-get update && apt-get install -y natpmpc

FROM alpine:3.21.2
RUN apk --no-cache add libc6-compat


WORKDIR /exporter
COPY --from=builder /bin/qbittorrent_port .
COPY --from=debian /usr/bin/natpmpc /usr/local/bin/natpmpc


# Command to run the application
CMD ["./qbittorrent_port"]
