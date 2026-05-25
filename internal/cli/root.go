// Package cli wires up the command tree for the application.
package cli

import (
	"errors"
	"fmt"
	"os"

	"github.com/spf13/cobra"
	"github.com/spf13/viper"
)

// BuildInfo carries version metadata injected at build time.
type BuildInfo struct {
	Version string
	Commit  string
	Date    string
}

var (
	buildInfo BuildInfo
	cfgFile   string
	verbose   bool
)

func newRootCmd() *cobra.Command {
	cmd := &cobra.Command{
		Use:           "go-template",
		Short:         "A starter Go CLI",
		Long:          "go-template is a starter template for building Go command-line applications.",
		SilenceUsage:  true,
		SilenceErrors: true,
		PersistentPreRunE: func(_ *cobra.Command, _ []string) error {
			return initConfig()
		},
		RunE: func(cmd *cobra.Command, _ []string) error {
			return cmd.Help()
		},
	}

	cmd.PersistentFlags().StringVar(&cfgFile, "config", "", "config file (default is $HOME/.go-template.yaml)")
	cmd.PersistentFlags().BoolVarP(&verbose, "verbose", "v", false, "enable verbose output")

	cmd.AddCommand(newVersionCmd())

	return cmd
}

// initConfig loads configuration from a file (if present) and the environment.
// Environment variables are read with the GO_TEMPLATE_ prefix.
func initConfig() error {
	if cfgFile != "" {
		viper.SetConfigFile(cfgFile)
	} else {
		home, err := os.UserHomeDir()
		if err != nil {
			return err
		}
		viper.AddConfigPath(home)
		viper.SetConfigType("yaml")
		viper.SetConfigName(".go-template")
	}

	viper.SetEnvPrefix("GO_TEMPLATE")
	viper.AutomaticEnv()

	if err := viper.ReadInConfig(); err != nil {
		var notFound viper.ConfigFileNotFoundError
		if !errors.As(err, &notFound) {
			return err
		}
	}

	return nil
}

// Execute builds the root command and runs it, exiting non-zero on error.
func Execute(info BuildInfo) {
	buildInfo = info
	if err := newRootCmd().Execute(); err != nil {
		fmt.Fprintln(os.Stderr, "error:", err)
		os.Exit(1)
	}
}
