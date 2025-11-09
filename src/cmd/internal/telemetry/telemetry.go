// Copyright 2024 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

//go:build !cmd_go_bootstrap && !compiler_bootstrap

// Package telemetry provides no-op implementations that inhibit telemetry collection.
package telemetry

import (
	"cmd/internal/telemetry/counter"
)

var openCountersCalled, maybeChildCalled bool

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

// Mode returns "off" to indicate telemetry is disabled.
func Mode() string {
	return "off"
}

// SetMode does nothing. Telemetry is disabled.
func SetMode(mode string) error {
	return nil
}

// Dir returns an empty string. Telemetry is disabled.
func Dir() string {
	return ""
}
