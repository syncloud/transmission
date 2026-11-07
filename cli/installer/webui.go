package installer

import (
	"fmt"
	"os"
	"os/exec"
	"path"
	"strings"
)

const (
	WebUIDefault = "default"
	WebUILegacy  = "legacy"
	webUIFile    = "web-ui"
)

type WebUI struct {
	file    string
	restart func() error
}

func NewWebUI(commonDir string) *WebUI {
	return &WebUI{
		file:    path.Join(commonDir, webUIFile),
		restart: restartDaemon,
	}
}

func (w *WebUI) Get() (string, error) {
	content, err := os.ReadFile(w.file)
	if err != nil {
		if os.IsNotExist(err) {
			return WebUIDefault, nil
		}
		return "", err
	}
	mode := strings.TrimSpace(string(content))
	if mode == WebUILegacy {
		return WebUILegacy, nil
	}
	return WebUIDefault, nil
}

func (w *WebUI) Set(mode string) error {
	if mode != WebUIDefault && mode != WebUILegacy {
		return fmt.Errorf("unknown web ui: %s, expected %s or %s", mode, WebUIDefault, WebUILegacy)
	}
	err := os.WriteFile(w.file, []byte(mode+"\n"), 0644)
	if err != nil {
		return err
	}
	return w.restart()
}

func restartDaemon() error {
	output, err := exec.Command("snap", "restart", App+".daemon").CombinedOutput()
	if err != nil {
		return fmt.Errorf("restart daemon: %v: %s", err, output)
	}
	return nil
}
