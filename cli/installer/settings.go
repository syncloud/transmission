package installer

import (
	"os"
	"path"

	cp "github.com/otiai10/copy"
)

const settingsFile = "settings.json"

type Settings struct {
	defaultDir string
	configDir  string
}

func NewSettings(defaultDir, configDir string) *Settings {
	return &Settings{defaultDir: defaultDir, configDir: configDir}
}

func (s *Settings) Seed() error {
	target := path.Join(s.configDir, settingsFile)
	_, err := os.Stat(target)
	if err == nil {
		return nil
	}
	if !os.IsNotExist(err) {
		return err
	}
	return cp.Copy(path.Join(s.defaultDir, settingsFile), target)
}
