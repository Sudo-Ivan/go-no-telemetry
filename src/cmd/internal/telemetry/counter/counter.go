// Copyright 2024 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

//go:build !cmd_go_bootstrap && !compiler_bootstrap

package counter

import (
	"flag"
)

var openCalled bool

func OpenCalled() bool { return openCalled }

// Open does nothing. Telemetry is disabled.
func Open() {
	openCalled = true
}

// Inc does nothing. Telemetry is disabled.
func Inc(name string) {
}

// Counter is a no-op counter type.
type Counter struct{}

// Inc does nothing. Telemetry is disabled.
func (c *Counter) Inc() {
}

// New returns a no-op counter. Telemetry is disabled.
func New(name string) *Counter {
	return &Counter{}
}

// StackCounter is a no-op stack counter type.
type StackCounter struct{}

// Inc does nothing. Telemetry is disabled.
func (c *StackCounter) Inc() {
}

// NewStack returns a no-op stack counter. Telemetry is disabled.
func NewStack(name string, depth int) *StackCounter {
	return &StackCounter{}
}

// CountFlags does nothing. Telemetry is disabled.
func CountFlags(prefix string, flagSet flag.FlagSet) {
}

// CountFlagValue does nothing. Telemetry is disabled.
func CountFlagValue(prefix string, flagSet flag.FlagSet, flagName string) {
}
