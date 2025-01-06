package main

import (
	"github.com/prometheus/client_golang/prometheus/promhttp"
	"log"
	"net/http"
	"rpi_scripts/exporter"
)

func main() {

	// Start exporters
	exporter.QBittorrent()
	exporter.OpenVpn()

	// Expose metrics on /metrics endpoint
	http.Handle("/metrics", promhttp.Handler())
	log.Fatal(http.ListenAndServe(":8000", nil))

}
