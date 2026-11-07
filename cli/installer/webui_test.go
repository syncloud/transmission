package installer

import (
	"os"
	"path"
	"testing"

	"github.com/stretchr/testify/assert"
)

func newTestWebUI(t *testing.T) (*WebUI, *int) {
	restarts := 0
	w := NewWebUI(t.TempDir())
	w.restart = func() error {
		restarts++
		return nil
	}
	return w, &restarts
}

func TestWebUIDefaultsWhenMissing(t *testing.T) {
	w, _ := newTestWebUI(t)
	mode, err := w.Get()
	assert.NoError(t, err)
	assert.Equal(t, WebUIDefault, mode)
}

func TestWebUISetLegacy(t *testing.T) {
	w, restarts := newTestWebUI(t)
	err := w.Set(WebUILegacy)
	assert.NoError(t, err)
	assert.Equal(t, 1, *restarts)

	mode, err := w.Get()
	assert.NoError(t, err)
	assert.Equal(t, WebUILegacy, mode)

	content, err := os.ReadFile(w.file)
	assert.NoError(t, err)
	assert.Equal(t, "legacy\n", string(content))
}

func TestWebUISetBackToDefault(t *testing.T) {
	w, restarts := newTestWebUI(t)
	assert.NoError(t, w.Set(WebUILegacy))
	assert.NoError(t, w.Set(WebUIDefault))
	assert.Equal(t, 2, *restarts)

	mode, err := w.Get()
	assert.NoError(t, err)
	assert.Equal(t, WebUIDefault, mode)
}

func TestWebUIRejectsUnknown(t *testing.T) {
	w, restarts := newTestWebUI(t)
	err := w.Set("classic")
	assert.Error(t, err)
	assert.Equal(t, 0, *restarts)
	_, err = os.Stat(path.Join(path.Dir(w.file), webUIFile))
	assert.True(t, os.IsNotExist(err))
}

func TestWebUIUnknownContentIsDefault(t *testing.T) {
	w, _ := newTestWebUI(t)
	assert.NoError(t, os.WriteFile(w.file, []byte("junk"), 0644))
	mode, err := w.Get()
	assert.NoError(t, err)
	assert.Equal(t, WebUIDefault, mode)
}
