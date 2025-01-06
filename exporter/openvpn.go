package exporter

import (
	"bufio"
	"fmt"
	"github.com/prometheus/client_golang/prometheus"
	"log"
	"os"
	"strconv"
	"strings"
	"time"
)

var (
	lastUpdate    = prometheus.NewGauge(prometheus.GaugeOpts{Name: "openvpn_last_update_timestamp", Help: "Last update timestamp from OpenVPN status file (in Unix time)"})
	tunReadBytes  = prometheus.NewGauge(prometheus.GaugeOpts{Name: "openvpn_tun_read_bytes_total", Help: "Total bytes read from TUN/TAP"})
	tunWriteBytes = prometheus.NewGauge(prometheus.GaugeOpts{Name: "openvpn_tun_write_bytes_total", Help: "Total bytes written to TUN/TAP"})
)

func init() {
	prometheus.MustRegister(lastUpdate)
	prometheus.MustRegister(tunReadBytes)
	prometheus.MustRegister(tunWriteBytes)
}
func fetchVPNStatus(file *os.File) {
	_, err := file.Seek(0, 0)
	if err != nil {
		log.Printf("Error seeking file: %v", err)
		return
	}

	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		line := scanner.Text()
		fields := strings.Split(line, ",")

		switch {
		case strings.HasPrefix(line, "Updated"):
			// Parse the last update time
			timestamp, err := time.Parse("2006-01-02 15:04:05", fields[1])
			if err != nil {
				log.Printf("Error parsing timestamp: %v", err)
				continue
			}
			lastUpdate.Set(float64(timestamp.Unix()))
		case strings.HasPrefix(line, "TUN/TAP read bytes"):
			// Parse TUN/TAP read bytes
			value, err := strconv.ParseFloat(fields[1], 64)
			if err != nil {
				log.Printf("Error parsing TUN/TAP read bytes: %v", err)
				continue
			}
			tunReadBytes.Set(value)
		case strings.HasPrefix(line, "TUN/TAP write bytes"):
			// Parse TUN/TAP write bytes
			value, err := strconv.ParseFloat(fields[1], 64)
			if err != nil {
				log.Printf("Error parsing TUN/TAP write bytes: %v", err)
				continue
			}
			tunWriteBytes.Set(value)
		}
	}

	if err := scanner.Err(); err != nil {
		log.Printf("Error reading OpenVPN status file: %v", err)
	}
}

func OpenVpn() {
	statusFile := os.Getenv("VPN_STATUS_FILE")

	file, err := os.Open(statusFile)
	if err != nil {
		log.Fatalf("Error opening OpenVPN status file: %v", err)
		return
	}
	defer func(file *os.File) {
		err := file.Close()
		if err != nil {
			log.Printf("Error closing OpenVPN status file: %v", err)
		}
	}(file)

	go func() {
		for {
			fetchVPNStatus(file)
			time.Sleep(2 * time.Second)
		}
	}()
	fmt.Println("OpenVPN Prometheus exporter running")

}
