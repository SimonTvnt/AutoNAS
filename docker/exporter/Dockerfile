# Stage 1: Build
FROM golang:1.23 AS builder

WORKDIR /rpi_scripts

ENV GOBIN=/bin

COPY go.mod go.sum ./
COPY main/exporter ./main/exporter
COPY exporter ./exporter

RUN go install ./...

# Stage 2: Minimal runtime
FROM alpine:latest
RUN apk --no-cache add libc6-compat

WORKDIR /exporter
COPY --from=builder /bin/exporter .

# Command to run the application
CMD ["./exporter"]
