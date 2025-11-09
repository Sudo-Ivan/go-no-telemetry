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

### Download and Install

#### Quick Install

Install via the automated installer script:

```bash
curl -fsSL https://raw.githubusercontent.com/Sudo-Ivan/go-no-telemetry/master/install.sh | sh
```

Or download and run manually:

```bash
curl -fsSL https://raw.githubusercontent.com/Sudo-Ivan/go-no-telemetry/master/install.sh -o install.sh
chmod +x install.sh
./install.sh
```

#### Build and install from source

Linux/macOS/BSD:

```bash
git clone https://github.com/Sudo-Ivan/go-no-telemetry.git
cd go-no-telemetry/src
./make.bash  # or ./all.bash for full tests
```

Windows:

```bash
git clone https://github.com/Sudo-Ivan/go-no-telemetry.git
cd go-no-telemetry/src
./make.bat  # or ./all.bat for full tests
```
