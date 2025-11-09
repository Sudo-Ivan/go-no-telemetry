// Copyright 2024 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

//go:build !cmd_go_bootstrap && !compiler_bootstrap

// Package telemetry provides no-op implementations that inhibit telemetry collection.
package telemetry

import (
	"os"
	"path/filepath"
	"strings"

	"cmd/internal/telemetry/counter"
)

var (
	openCountersCalled, maybeChildCalled bool
)

func modeFile() string {
	dir := Dir()
	if dir == "" {
		return ""
	}
	return filepath.Join(dir, "mode")
}

func readMode() string {
	modeFile := modeFile()
	if modeFile == "" {
		return "local"
	}
	data, err := os.ReadFile(modeFile)
	if err != nil {
		return "local"
	}
	mode := strings.TrimSpace(string(data))
	if mode == "off" || mode == "local" || mode == "on" {
		return mode
	}
	return "local"
}

// MaybeParent does nothing. Telemetry is disabled.
func MaybeParent() {
	if !counter.OpenCalled() || !maybeChildCalled {
		panic("MaybeParent must be called after OpenCounters and MaybeChild")
	}
}

// MaybeChild does nothing. Telemetry is disabled.
func MaybeChild() {
	maybeChildCalled = true
}

// Mode returns the current telemetry mode. Defaults to "local".
func Mode() string {
	return readMode()
}

// SetMode stores the telemetry mode but does not enable telemetry collection.
func SetMode(mode string) error {
	if mode != "off" && mode != "local" && mode != "on" {
		return nil
	}
	modeFile := modeFile()
	if modeFile == "" {
		return nil
	}
	dir := filepath.Dir(modeFile)
	if err := os.MkdirAll(dir, 0755); err != nil {
		return err
	}
	if err := os.WriteFile(modeFile, []byte(mode), 0644); err != nil {
		return err
	}
	if mode == "local" || mode == "on" {
		localDir := filepath.Join(dir, "local")
		os.MkdirAll(localDir, 0755)
	} else if mode == "off" {
		localDir := filepath.Join(dir, "local")
		os.RemoveAll(localDir)
	}
	return nil
}

// Dir returns the telemetry directory path, but telemetry collection is disabled.
func Dir() string {
	configDir, err := os.UserConfigDir()
	if err != nil {
		return ""
	}
	return filepath.Join(configDir, "go", "telemetry")
}
