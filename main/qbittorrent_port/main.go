package main

import (
	"fmt"
	"os"
	"time"

	"rpi_scripts/scripts"
)

func main() {
	gateway := os.Getenv("VPN_GATEWAY")
	configFile := os.Getenv("QB_CONFIG_FILE")

	file, err := os.OpenFile(configFile, os.O_RDWR, 0644)

	if err != nil {
		fmt.Println("Error opening qBittorrent config file:", err)
		return
	}

	defer func(file *os.File) {
		err := file.Close()
		if err != nil {

		}
	}(file)

	for {
		output, err := scripts.RunNatpmpcCommands(gateway)
		if err != nil {
			fmt.Println("ERROR with natpmpc command", output, err)
			break
		}

		mappedPort := scripts.ExtractMappedPort(output)
		if mappedPort != "" {
			if err := scripts.UpdateQbittorrentConfig(mappedPort, file); err != nil {
				fmt.Println("Failed to update qBittorrent config:", err)
			}
		}

		time.Sleep(45 * time.Second)
	}
}
