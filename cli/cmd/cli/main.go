package main

import (
	"fmt"
	"github.com/spf13/cobra"
	"go.uber.org/zap"
	"hooks/installer"
	"hooks/log"
	"os"
)

func main() {
	logger := log.Logger()

	var cmd = &cobra.Command{
		Use:          "cli",
		SilenceUsage: true,
	}

	cmd.AddCommand(&cobra.Command{
		Use: "storage-change",
		RunE: func(cmd *cobra.Command, args []string) error {
			logger.Info("storage-change")
			return installer.New().StorageChange()
		},
	})

	cmd.AddCommand(&cobra.Command{
		Use: "access-change",
		Run: func(cmd *cobra.Command, args []string) {
			logger.Warn("access-change is not implemented yet")
		},
	})

	cmd.AddCommand(&cobra.Command{
		Use: "backup-pre-stop",
		Run: func(cmd *cobra.Command, args []string) {
			logger.Warn("backup-pre-stop is not implemented yet")
		},
	})

	cmd.AddCommand(&cobra.Command{
		Use: "restore-pre-start",
		Run: func(cmd *cobra.Command, args []string) {
			logger.Warn("restore-pre-start is not implemented yet")
		},
	})

	cmd.AddCommand(&cobra.Command{
		Use: "restore-post-start",
		Run: func(cmd *cobra.Command, args []string) {
			logger.Warn("restore-post-start is not implemented yet")
		},
	})

	cmd.AddCommand(&cobra.Command{
		Use:       "web-ui [default|legacy]",
		Short:     "Show or switch the web UI (legacy is the 4.0 UI)",
		Args:      cobra.MaximumNArgs(1),
		ValidArgs: []string{installer.WebUIDefault, installer.WebUILegacy},
		RunE: func(cmd *cobra.Command, args []string) error {
			webUI := installer.NewWebUI(installer.CommonDir)
			if len(args) == 0 {
				mode, err := webUI.Get()
				if err != nil {
					return err
				}
				fmt.Println(mode)
				return nil
			}
			logger.Info("web-ui", zap.String("mode", args[0]))
			return webUI.Set(args[0])
		},
	})

	err := cmd.Execute()
	if err != nil {
		fmt.Print(err)
		os.Exit(1)
	}
}
