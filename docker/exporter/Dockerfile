# Stage 1: Build
FROM golang:1.23 AS builder

# Set the working directory inside the container
WORKDIR /app

# Copy Go module files
COPY go.mod go.sum ./

# Download dependencies
RUN go mod download

# Copy the application source code
COPY main/exporter ./main/exporter
COPY exporter ./exporter

# Set GOBIN to ensure the binary is placed in /app/bin
ENV GOBIN=/app/bin

# Build the binary using go install
WORKDIR /app/main/exporter
RUN go install .

# Stage 2: Minimal runtime
FROM alpine:latest

# Set working directory in the minimal image
WORKDIR /app

# Copy the binary from the builder stage
COPY --from=builder /app/bin/exporter .

# Expose the Prometheus exporter port
EXPOSE 8000

# Command to run the application
CMD ["./exporter"]
