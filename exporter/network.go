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
	rxBytes = prometheus.NewGaugeVec(prometheus.GaugeOpts{Name: "network_interface_rx_bytes_total", Help: "Total bytes received for each interface"}, []string{"interface"})
	txBytes = prometheus.NewGaugeVec(prometheus.GaugeOpts{Name: "network_interface_tx_bytes_total", Help: "Total bytes transmitted for each interface"}, []string{"interface"})
)

func init() {
	prometheus.MustRegister(rxBytes)
	prometheus.MustRegister(txBytes)
}
func fetchInterfaceStatus(file *os.File) {
	_, err := file.Seek(0, 0)
	if err != nil {
		log.Printf("Error seeking file: %v", err)
		return
	}

	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		line := scanner.Text()
		if strings.Contains(line, "Inter-") || strings.Contains(line, " face") || strings.TrimSpace(line) == "" {
			continue
		}
		fields := strings.Fields(line)
		iface := strings.Trim(fields[0], ":")
		rx, _ := strconv.ParseFloat(fields[1], 64)
		tx, _ := strconv.ParseFloat(fields[9], 64)

		rxBytes.WithLabelValues(iface).Set(rx)
		txBytes.WithLabelValues(iface).Set(tx)
	}
}

func NetworkInterface() {
	statusFile := os.Getenv("NETWORK_INTERFACE_STATUS")

	file, err := os.Open(statusFile)
	if err != nil {
		log.Fatalf("Error opening network interface status file: %v", err)
		return
	}

	go func() {
		defer func(file *os.File) {
			err := file.Close()
			if err != nil {
				log.Printf("Error closing network interface status file: %v", err)
			}
		}(file)

		for {
			fetchInterfaceStatus(file)
			time.Sleep(2 * time.Second)
		}
	}()
	fmt.Println("Network Interface Prometheus exporter running")

}
