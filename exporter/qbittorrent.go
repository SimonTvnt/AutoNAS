package exporter

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"time"

	"github.com/prometheus/client_golang/prometheus"
)

type Torrent struct {
	Name       string  `json:"name"`
	UpSpeed    float64 `json:"upspeed"`
	DlSpeed    float64 `json:"dlspeed"`
	Uploaded   float64 `json:"uploaded"`
	Downloaded float64 `json:"downloaded"`
}

var (
	// Per torrent metrics
	uploadSpeed     = prometheus.NewGaugeVec(prometheus.GaugeOpts{Name: "qbittorrent_torrent_upload_speed_bytes", Help: "Upload speed per torrent (bytes/s)"}, []string{"torrent_name"})
	downloadSpeed   = prometheus.NewGaugeVec(prometheus.GaugeOpts{Name: "qbittorent_torrent_download_speed_bytes", Help: "Download speed per torrent (bytes/s)"}, []string{"torrent_name"})
	uploadedTotal   = prometheus.NewGaugeVec(prometheus.GaugeOpts{Name: "qbittorent_torrent_uploaded_total_bytes", Help: "Total uploaded data per torrent (bytes)"}, []string{"torrent_name"})
	downloadedTotal = prometheus.NewGaugeVec(prometheus.GaugeOpts{Name: "qbittorent_torrent_downloaded_total_bytes", Help: "Total downloaded data per torrent (bytes)"}, []string{"torrent_name"})
	ratioPerTorrent = prometheus.NewGaugeVec(prometheus.GaugeOpts{Name: "qbittorent_torrent_ratio", Help: "Upload/download ratio per torrent"}, []string{"torrent_name"})

	// Global metrics
	totalUploaded   = prometheus.NewGauge(prometheus.GaugeOpts{Name: "qbittorent_total_uploaded_bytes", Help: "Total uploaded data across all torrents (bytes)"})
	totalDownloaded = prometheus.NewGauge(prometheus.GaugeOpts{Name: "qbittorent_total_downloaded_bytes", Help: "Total downloaded data across all torrents (bytes)"})
	totalRatio      = prometheus.NewGauge(prometheus.GaugeOpts{Name: "qbittorent_total_ratio", Help: "Global upload/download ratio"})
)

func init() {
	// Register metrics
	prometheus.MustRegister(uploadSpeed)
	prometheus.MustRegister(downloadSpeed)
	prometheus.MustRegister(uploadedTotal)
	prometheus.MustRegister(downloadedTotal)
	prometheus.MustRegister(ratioPerTorrent)
	prometheus.MustRegister(totalUploaded)
	prometheus.MustRegister(totalDownloaded)
	prometheus.MustRegister(totalRatio)
}

func fetchTorrentStats(apiURL string) {
	client := &http.Client{Timeout: 10 * time.Second}

	// Fetch torrent info
	req, err := http.NewRequest("GET", apiURL+"/torrents/info", nil)
	if err != nil {
		log.Println("Error creating request for torrents:", err)
		return
	}
	resp, err := client.Do(req)
	if err != nil {
		log.Println("Error fetching torrent stats:", err)
		return
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		log.Println("Error response from qBittorrent API:", resp.StatusCode)
		return
	}

	var torrents []Torrent
	if err := json.NewDecoder(resp.Body).Decode(&torrents); err != nil {
		log.Println("Error decoding torrent stats:", err)
		return
	}

	// Initialize totals
	var totalUp, totalDown float64
	for _, torrent := range torrents {
		torrentName := torrent.Name

		// Update per torrent metrics
		uploadSpeed.WithLabelValues(torrentName).Set(torrent.UpSpeed)
		downloadSpeed.WithLabelValues(torrentName).Set(torrent.DlSpeed)
		uploadedTotal.WithLabelValues(torrentName).Set(torrent.Uploaded)
		downloadedTotal.WithLabelValues(torrentName).Set(torrent.Downloaded)

		// Calculate and set ratio for each torrent
		if torrent.Downloaded > 0 {
			ratioPerTorrent.WithLabelValues(torrentName).Set(torrent.Uploaded / torrent.Downloaded)
		} else {
			ratioPerTorrent.WithLabelValues(torrentName).Set(0)
		}

		// Accumulate global totals
		totalUp += torrent.Uploaded
		totalDown += torrent.Downloaded
	}

	// Update global metrics
	totalUploaded.Set(totalUp)
	totalDownloaded.Set(totalDown)
	if totalDown > 0 {
		totalRatio.Set(totalUp / totalDown)
	} else {
		totalRatio.Set(0)
	}
}

func QBittorrent() {
	apiURL := os.Getenv("QB_API_URL")

	// Periodically fetch torrent stats
	go func() {
		for {
			fetchTorrentStats(apiURL)
			time.Sleep(1 * time.Second)
		}
	}()
	fmt.Println("qBittorrent Prometheus exporter running on :8000")
}
