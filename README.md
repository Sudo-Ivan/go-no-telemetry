# The Go Programming Language with no telemetry

Go is an open source programming language that makes it easy to build simple,
reliable, and efficient software.

Unless otherwise noted, the Go source files are distributed under the
BSD-style license found in the LICENSE file.

## Features of this fork

- No telemetry
- No code contacting remote servers
- Kept updated with upstream Go (except any telemetry related code)
- Once built, can be used to bootstrap future Go versions

### Build and install via the single script:

```bash
curl -fsSL https://raw.githubusercontent.com/Sudo-Ivan/go-no-telemetry/refs/heads/no-telemetry-go1.24.10/install.sh -o install.sh
chmod +x install.sh
./install.sh
```

### Build and install from source

Linux/macOS/BSD:

```bash
git clone --branch no-telemetry-go1.24.10 https://github.com/Sudo-Ivan/go-no-telemetry.git
cd go-no-telemetry/src
./make.bash  # or ./all.bash for full tests
```

Windows:

```bash
git clone --branch no-telemetry-go1.24.10 https://github.com/Sudo-Ivan/go-no-telemetry.git
cd go-no-telemetry/src
./make.bat  # or ./all.bat for full tests
```
