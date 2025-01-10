package scripts

import (
	"bufio"
	"fmt"
	"os"
	"os/exec"
	"regexp"
	"strings"
)

func RunNatpmpcCommands(gateway string) (string, error) {
	cmd := fmt.Sprintf(`natpmpc -a 1 0 udp 60 -g %s && natpmpc -a 1 0 tcp 60 -g %s`, gateway, gateway)
	output, err := execShellCommand(cmd)
	return output, err
}

func execShellCommand(command string) (string, error) {
	cmd := exec.Command("sh", "-c", command) // Use "sh" instead of "bash"
	output, err := cmd.CombinedOutput()
	return string(output), err
}

func ExtractMappedPort(output string) string {
	pattern := `Mapped public port (\d+) protocol TCP to local port 0`
	r := regexp.MustCompile(pattern)
	match := r.FindStringSubmatch(output)

	if len(match) > 1 {
		return match[1]
	}
	return ""
}

func UpdateQbittorrentConfig(port string, file *os.File) error {
	if _, err := file.Seek(0, 0); err != nil {
		return fmt.Errorf("error seeking qBittorrent config file: %w", err)
	}

	// Read and update the configuration in memory
	var updatedContent strings.Builder
	found := false
	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		line := scanner.Text()
		if strings.HasPrefix(line, "Session\\Port=") {
			updatedContent.WriteString(fmt.Sprintf("Session\\Port=%s\n", port))
			found = true
		} else {
			updatedContent.WriteString(line + "\n")
		}
	}

	if err := scanner.Err(); err != nil {
		return fmt.Errorf("error reading qBittorrent config file: %w", err)
	}

	// If the key wasn't found, append it
	if !found {
		updatedContent.WriteString(fmt.Sprintf("Session\\Port=%s\n", port))
	}

	// Write the updated content back to the file
	if err := file.Truncate(0); err != nil {
		return fmt.Errorf("error truncating qBittorrent config file: %w", err)
	}

	if _, err := file.Seek(0, 0); err != nil {
		return fmt.Errorf("error seeking qBittorrent config file: %w", err)
	}

	if _, err := file.WriteString(updatedContent.String()); err != nil {
		return fmt.Errorf("error writing qBittorrent config file: %w", err)
	}

	fmt.Printf("Updated qBittorrent port to %s\n", port)
	return nil
}
