package installer

import (
	"os"
	"path"
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestSeedCreatesMissingSettings(t *testing.T) {
	defaultDir := t.TempDir()
	configDir := t.TempDir()
	err := os.WriteFile(path.Join(defaultDir, settingsFile), []byte(`{"default":true}`), 0644)
	assert.NoError(t, err)

	err = NewSettings(defaultDir, configDir).Seed()
	assert.NoError(t, err)

	content, err := os.ReadFile(path.Join(configDir, settingsFile))
	assert.NoError(t, err)
	assert.Equal(t, `{"default":true}`, string(content))
}

func TestSeedKeepsExistingSettings(t *testing.T) {
	defaultDir := t.TempDir()
	configDir := t.TempDir()
	err := os.WriteFile(path.Join(defaultDir, settingsFile), []byte(`{"default":true}`), 0644)
	assert.NoError(t, err)
	err = os.WriteFile(path.Join(configDir, settingsFile), []byte(`{"user":true}`), 0644)
	assert.NoError(t, err)

	err = NewSettings(defaultDir, configDir).Seed()
	assert.NoError(t, err)

	content, err := os.ReadFile(path.Join(configDir, settingsFile))
	assert.NoError(t, err)
	assert.Equal(t, `{"user":true}`, string(content))
}
