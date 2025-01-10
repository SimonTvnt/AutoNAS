FROM golang:1.23

WORKDIR /rpi_scripts

ENV GOBIN=/bin

COPY go.mod go.sum ./
COPY main ./main
COPY scripts ./scripts
COPY exporter ./exporter

RUN go install ./...