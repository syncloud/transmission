package installer

import (
	"fmt"
	"github.com/google/uuid"
	cp "github.com/otiai10/copy"
github.com/syncloud/golib/config"
	"hooks/platform"
	"os"
	"path"
	"strings"
)

const (
	App       = "transmission"
	AppDir    = "/snap/transmission/current"
	DataDir   = "/var/snap/transmission/current"
	CommonDir = "/var/snap/transmission/common"
)

type Installer struct {
	newVersionFile                   string
	currentVersionFile               string
	configDir                        string
	platformClient                   *platform.Client
}

func New() *Installer {
	configDir := path.Join(DataDir, "config")

	return &Installer{
		newVersionFile:                   path.Join(AppDir, "version"),
		currentVersionFile:               path.Join(DataDir, "version"),
		configDir:                        configDir,
		platformClient:                   platform.New(),
	}
}

func (i *Installer) Install() error {
	err := CreateUser(App)
	if err != nil {
		return err
	}

	err = os.Mkdir(path.Join(DataDir, "nginx"), 0755)
	if err != nil {
		return err
	}


	err = i.UpdateConfigs()
	if err != nil {
		return err
	}

	err = i.FixPermissions()
	if err != nil {
		return err
	}

	err = i.StorageChange()
	if err != nil {
		return err
	}
	return nil
}

func (i *Installer) Configure() error {
	return i.UpdateVersion()
}

func (i *Installer) PreRefresh() error {
	return nil
}

func (i *Installer) PostRefresh() error {
	err := i.UpdateConfigs()
	if err != nil {
		return err
	}

	err = i.ClearVersion()
	if err != nil {
		return err
	}

	err = i.FixPermissions()
	if err != nil {
		return err
	}

	err = i.StorageChange()
	if err != nil {
		return err
	}

	return nil

}
func (i *Installer) StorageChange() error {
	storageDir, err := i.platformClient.InitStorage(App, App)
	if err != nil {
		return err
	}

	err = os.Mkdir(path.Join(storageDir, "download"), 0755)
	if err != nil {
		if !os.IsExist(err) {
			return err
		}
	}

 err = Chown(storageDir, App)
	if err != nil {
		return err
	}
	return nil
}

func (i *Installer) ClearVersion() error {
	return os.RemoveAll(i.currentVersionFile)
}

func (i *Installer) UpdateVersion() error {
	return cp.Copy(i.newVersionFile, i.currentVersionFile)
}

func (i *Installer) UpdateConfigs() error {

	err := cp.Copy(path.Join(AppDir, "config"), path.Join(DataDir, "config"))
	if err != nil {
		return err
	}

	authDomain, err := i.platformClient.GetAppDomainName("auth")
	if err != nil {
		return err
	}
 domain, err := i.platformClient.GetAppDomainName(App)
	if err != nil {
		return err
	}
		vars := map[string]string{
		"domain":         domain,
		"auth_domain": authDomain,
	}

	err = config.Generate(
		path.Join(AppDir, "config"),
		path.Join(DataDir, "config"),
		vars,
	)

	return err

}

func (i *Installer) FixPermissions() error {
	err := Chown(DataDir, App)
	if err != nil {
		return err
	}
	err = Chown(CommonDir, App)
	if err != nil {
		return err
	}
	return nil
}
