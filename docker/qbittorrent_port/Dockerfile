FROM base AS builder

FROM debian:bullseye AS debian
RUN apt-get update && apt-get install -y natpmpc

FROM alpine:3.21.2
RUN apk --no-cache add libc6-compat bash curl gcc musl-dev make

# Build and install libnatpmp
RUN curl -LO https://miniupnp.tuxfamily.org/files/libnatpmp-20150609.tar.gz && \
    tar xvf libnatpmp-20150609.tar.gz && \
    cd libnatpmp-20150609 && \
    make && \
    make install && \
    cd .. && \
    rm -rf libnatpmp libnatpmp-20150609.tar.gz

WORKDIR /exporter
COPY --from=builder /bin/qbittorrent_port .
COPY --from=debian /usr/bin/natpmpc /usr/local/bin/natpmpc


# Command to run the application
CMD ["./qbittorrent_port"]
