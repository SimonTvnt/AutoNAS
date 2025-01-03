# Use the official Golang image as the base image
FROM golang:1.23 as builder

# Set the working directory inside the container
WORKDIR /rpi_scripts
ENV PATH=/root/go/bin:/usr/lib/go/bin:$PATH

# Copy the Go module files and download dependencies
COPY go.mod go.sum ./
COPY main.go main.go
RUN go mod download

# Copy the Go source code into the container
COPY exporter exporter

# Build the Go binary
RUN go build -o main .

# Stage 2: Minimal runtime
FROM alpine:latest

# Set working directory in the minimal image
WORKDIR /rpi_scripts

# Copy the compiled binary from the builder stage
COPY --from=builder /rpi_scripts/main .

# Expose the port for the Prometheus exporter
EXPOSE 8000

# Set the command to run the binary
CMD ["./main"]