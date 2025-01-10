FROM base AS builder

FROM alpine:3.21.2
RUN apk --no-cache add libc6-compat

WORKDIR /exporter
COPY --from=builder /bin/exporter .

# Command to run the application
CMD ["./exporter"]
