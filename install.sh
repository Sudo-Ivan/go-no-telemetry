#!/bin/sh
# POSIX-compliant installation script for go-no-telemetry

set -e

# Colors (will be disabled if output is not a terminal)
RED=''
GREEN=''
YELLOW=''
BLUE=''
CYAN=''
BOLD=''
NC=''

# Detect if output is a terminal
if [ -t 1 ]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    CYAN='\033[0;36m'
    BOLD='\033[1m'
    NC='\033[0m'
fi

# Constants
REPO_URL="https://github.com/Sudo-Ivan/go-no-telemetry.git"
DEFAULT_BRANCH="master"
DEFAULT_INSTALL_DIR="/usr/local/go-no-telemetry"
DEFAULT_SYSTEM_GO="/usr/bin/go"
DEFAULT_SYSTEM_GOFMT="/usr/bin/gofmt"
DEFAULT_SYSTEM_GO_DIR="/usr/lib/go/bin"
MIN_GO_VERSION="1.22"

# Error handling
error() {
    printf "${RED}${BOLD}Error:${NC} %s\n" "$1" >&2
    exit 1
}

warning() {
    printf "${YELLOW}${BOLD}Warning:${NC} %s\n" "$1" >&2
}

info() {
    printf "${BLUE}${BOLD}Info:${NC} %s\n" "$1"
}

success() {
    printf "${GREEN}${BOLD}Success:${NC} %s\n" "$1"
}

# Check for required commands
check_command() {
    if ! command -v "$1" >/dev/null 2>&1; then
        error "$1 is required but not installed. Please install it first."
    fi
}

# Detect sudo/doas
detect_sudo() {
    if command -v doas >/dev/null 2>&1; then
        SUDO_CMD="doas"
    elif command -v sudo >/dev/null 2>&1; then
        SUDO_CMD="sudo"
    else
        error "Neither sudo nor doas found. Please install one."
    fi
}

# Check if running as root
check_root() {
    if [ "$(id -u)" -eq 0 ]; then
        SUDO_CMD=""
        return 0
    fi
    return 1
}

# Prompt for sudo/doas password
prompt_sudo() {
    if [ -z "$SUDO_CMD" ]; then
        return 0
    fi
    printf "${CYAN}This operation requires elevated privileges.${NC}\n"
    printf "Please enter your password for ${BOLD}${SUDO_CMD}${NC}: "
    if ! $SUDO_CMD -v; then
        error "Failed to authenticate with $SUDO_CMD"
    fi
}

# Detect shell config file
detect_shell_config() {
    if [ -n "$ZSH_VERSION" ]; then
        if [ -f "$HOME/.zshrc" ]; then
            SHELL_CONFIG="$HOME/.zshrc"
            SHELL_NAME="zsh"
        elif [ -f "$HOME/.zprofile" ]; then
            SHELL_CONFIG="$HOME/.zprofile"
            SHELL_NAME="zsh"
        else
            SHELL_CONFIG="$HOME/.zshrc"
            SHELL_NAME="zsh"
        fi
    elif [ -n "$FISH_VERSION" ]; then
        if [ -d "$HOME/.config/fish" ]; then
            SHELL_CONFIG="$HOME/.config/fish/config.fish"
            SHELL_NAME="fish"
        else
            mkdir -p "$HOME/.config/fish"
            SHELL_CONFIG="$HOME/.config/fish/config.fish"
            SHELL_NAME="fish"
        fi
    else
        if [ -f "$HOME/.bashrc" ]; then
            SHELL_CONFIG="$HOME/.bashrc"
            SHELL_NAME="bash"
        elif [ -f "$HOME/.bash_profile" ]; then
            SHELL_CONFIG="$HOME/.bash_profile"
            SHELL_NAME="bash"
        elif [ -f "$HOME/.profile" ]; then
            SHELL_CONFIG="$HOME/.profile"
            SHELL_NAME="sh"
        else
            SHELL_CONFIG="$HOME/.bashrc"
            SHELL_NAME="bash"
        fi
    fi
}

# Check for bootstrap Go
check_bootstrap_go() {
    if ! command -v go >/dev/null 2>&1; then
        error "Go is required for building. Please install Go $MIN_GO_VERSION or later first."
    fi
    
    GO_VERSION=$(go version | awk '{print $3}' | sed 's/go//')
    GO_MAJOR=$(echo "$GO_VERSION" | cut -d. -f1)
    GO_MINOR=$(echo "$GO_VERSION" | cut -d. -f2)
    
    MIN_MAJOR=$(echo "$MIN_GO_VERSION" | cut -d. -f1)
    MIN_MINOR=$(echo "$MIN_GO_VERSION" | cut -d. -f2)
    
    if [ "$GO_MAJOR" -lt "$MIN_MAJOR" ] || ([ "$GO_MAJOR" -eq "$MIN_MAJOR" ] && [ "$GO_MINOR" -lt "$MIN_MINOR" ]); then
        error "Go $GO_VERSION found, but Go $MIN_GO_VERSION or later is required for building."
    fi
    
    info "Found Go $GO_VERSION (bootstrap)"
}

# Clone repository
clone_repo() {
    local branch="$1"

    if [ -d ".git" ]; then
        info "Already in a git repository, updating..."
        if git pull --rebase; then
            success "Repository updated"
            REPO_DIR="$(pwd)"
            return 0
        else
            warning "Failed to update repository, continuing with current state"
            REPO_DIR="$(pwd)"
            return 0
        fi
    fi

    if [ -d "go-no-telemetry" ] && [ -d "go-no-telemetry/.git" ]; then
        info "Found existing repository in go-no-telemetry/, updating..."
        cd go-no-telemetry
        if git pull --rebase; then
            success "Repository updated"
            REPO_DIR="$(pwd)"
            return 0
        else
            warning "Failed to update repository, continuing with current state"
            REPO_DIR="$(pwd)"
            return 0
        fi
    fi

    info "Cloning repository to current directory..."
    if [ -n "$branch" ] && [ "$branch" != "$DEFAULT_BRANCH" ]; then
        info "Using branch: $branch"
        if ! git clone --branch "$branch" "$REPO_URL" go-no-telemetry; then
            error "Failed to clone repository branch $branch"
        fi
    else
        if ! git clone "$REPO_URL" go-no-telemetry; then
            error "Failed to clone repository"
        fi
    fi
    cd go-no-telemetry
    REPO_DIR="$(pwd)"
    success "Repository cloned"
}

# Build Go
build_go() {
    local with_tests="$1"
    info "Building Go (this may take a while)..."
    
    cd "$REPO_DIR/src"
    
    if [ "$with_tests" = "yes" ]; then
        info "Running full build with tests..."
        if ! ./all.bash; then
            error "Build with tests failed"
        fi
    else
        info "Running build without tests..."
        if ! ./make.bash; then
            error "Build failed"
        fi
    fi
    
    if [ ! -f "$REPO_DIR/bin/go" ]; then
        error "Build completed but go binary not found"
    fi
    
    success "Build completed successfully"
}

# Get GOOS and GOARCH from built Go
get_go_platform() {
    if [ ! -f "$REPO_DIR/bin/go" ]; then
        error "Go binary not found. Build Go first."
    fi
    
    GOOS=$("$REPO_DIR/bin/go" env GOOS)
    GOARCH=$("$REPO_DIR/bin/go" env GOARCH)
    TOOL_DIR="$REPO_DIR/pkg/tool/${GOOS}_${GOARCH}"
    
    if [ ! -d "$TOOL_DIR" ]; then
        error "Tool directory not found: $TOOL_DIR"
    fi
}

# Install to system location
install_system() {
    local install_dir="$1"
    local override="$2"
    
    get_go_platform
    
    if [ "$override" = "yes" ]; then
        info "Installing to system location (overriding existing Go)..."
        prompt_sudo
        
        if [ -f "$DEFAULT_SYSTEM_GO_DIR/go" ]; then
            info "Backing up existing Go binaries..."
            $SUDO_CMD cp "$DEFAULT_SYSTEM_GO_DIR/go" "$DEFAULT_SYSTEM_GO_DIR/go.backup" 2>/dev/null || true
            $SUDO_CMD cp "$DEFAULT_SYSTEM_GO_DIR/gofmt" "$DEFAULT_SYSTEM_GO_DIR/gofmt.backup" 2>/dev/null || true
        fi
        
        $SUDO_CMD mkdir -p "$(dirname "$DEFAULT_SYSTEM_GO_DIR")"
        $SUDO_CMD cp "$REPO_DIR/bin/go" "$DEFAULT_SYSTEM_GO_DIR/go"
        $SUDO_CMD cp "$REPO_DIR/bin/gofmt" "$DEFAULT_SYSTEM_GO_DIR/gofmt"
        $SUDO_CMD chmod +x "$DEFAULT_SYSTEM_GO_DIR/go" "$DEFAULT_SYSTEM_GO_DIR/gofmt"
        
        info "Installing toolchain binaries (compile, link, etc.)..."
        SYSTEM_TOOL_DIR="/usr/lib/go/pkg/tool/${GOOS}_${GOARCH}"
        $SUDO_CMD mkdir -p "$SYSTEM_TOOL_DIR"
        if [ -n "$(ls -A "$TOOL_DIR" 2>/dev/null)" ]; then
            $SUDO_CMD cp "$TOOL_DIR"/* "$SYSTEM_TOOL_DIR/" || error "Failed to copy toolchain binaries"
            if [ -n "$(ls -A "$SYSTEM_TOOL_DIR" 2>/dev/null)" ]; then
                $SUDO_CMD chmod +x "$SYSTEM_TOOL_DIR"/*
            fi
        else
            warning "Tool directory is empty: $TOOL_DIR"
        fi
        
        info "Installing standard library source..."
        $SUDO_CMD cp -r "$REPO_DIR/src" /usr/lib/go/ 2>/dev/null || true
        
        success "Installed to $DEFAULT_SYSTEM_GO_DIR"
        success "Installed toolchain to $SYSTEM_TOOL_DIR"
    else
        info "Installing to custom directory: $install_dir"
        prompt_sudo
        
        $SUDO_CMD mkdir -p "$install_dir/bin"
        $SUDO_CMD cp "$REPO_DIR/bin/go" "$install_dir/bin/"
        $SUDO_CMD cp "$REPO_DIR/bin/gofmt" "$install_dir/bin/"
        $SUDO_CMD chmod +x "$install_dir/bin/go" "$install_dir/bin/gofmt"
        
        info "Installing toolchain binaries (compile, link, etc.)..."
        CUSTOM_TOOL_DIR="$install_dir/pkg/tool/${GOOS}_${GOARCH}"
        $SUDO_CMD mkdir -p "$CUSTOM_TOOL_DIR"
        if [ -n "$(ls -A "$TOOL_DIR" 2>/dev/null)" ]; then
            $SUDO_CMD cp "$TOOL_DIR"/* "$CUSTOM_TOOL_DIR/" || error "Failed to copy toolchain binaries"
            if [ -n "$(ls -A "$CUSTOM_TOOL_DIR" 2>/dev/null)" ]; then
                $SUDO_CMD chmod +x "$CUSTOM_TOOL_DIR"/*
            fi
        else
            warning "Tool directory is empty: $TOOL_DIR"
        fi
        
        info "Installing standard library source..."
        $SUDO_CMD cp -r "$REPO_DIR/src" "$install_dir/"
        
        detect_shell_config
        add_to_path "$install_dir/bin"
        
        success "Installed to $install_dir/bin"
        success "Installed toolchain to $CUSTOM_TOOL_DIR"
        success "Installed source to $install_dir/src"
        info "Added to PATH in $SHELL_CONFIG"
        printf "${YELLOW}Please run: source $SHELL_CONFIG${NC}\n"
        printf "${CYAN}Set GOROOT=$install_dir if needed${NC}\n"
    fi
}

# Install with renamed binaries
install_renamed() {
    local install_dir="$1"
    local go_name="$2"
    local gofmt_name="$3"
    
    get_go_platform
    
    info "Installing with renamed binaries..."
    prompt_sudo
    
    $SUDO_CMD mkdir -p "$install_dir/bin"
    $SUDO_CMD cp "$REPO_DIR/bin/go" "$install_dir/bin/$go_name"
    $SUDO_CMD cp "$REPO_DIR/bin/gofmt" "$install_dir/bin/$gofmt_name"
    $SUDO_CMD chmod +x "$install_dir/bin/$go_name" "$install_dir/bin/$gofmt_name"
    
    info "Installing toolchain binaries (compile, link, etc.)..."
    CUSTOM_TOOL_DIR="$install_dir/pkg/tool/${GOOS}_${GOARCH}"
    $SUDO_CMD mkdir -p "$CUSTOM_TOOL_DIR"
    if [ -n "$(ls -A "$TOOL_DIR" 2>/dev/null)" ]; then
        $SUDO_CMD cp "$TOOL_DIR"/* "$CUSTOM_TOOL_DIR/" || error "Failed to copy toolchain binaries"
        if [ -n "$(ls -A "$CUSTOM_TOOL_DIR" 2>/dev/null)" ]; then
            $SUDO_CMD chmod +x "$CUSTOM_TOOL_DIR"/*
        fi
    else
        warning "Tool directory is empty: $TOOL_DIR"
    fi
    
    info "Installing standard library source..."
    $SUDO_CMD cp -r "$REPO_DIR/src" "$install_dir/"
    
    detect_shell_config
    add_to_path "$install_dir/bin"
    
    success "Installed as $go_name and $gofmt_name"
    success "Installed toolchain to $CUSTOM_TOOL_DIR"
    success "Installed source to $install_dir/src"
    info "Added to PATH in $SHELL_CONFIG"
    printf "${YELLOW}Please run: source $SHELL_CONFIG${NC}\n"
    printf "${CYAN}Use: $go_name version${NC}\n"
    printf "${CYAN}Set GOROOT=$install_dir if needed${NC}\n"
}

# Add to PATH in shell config
add_to_path() {
    local path_dir="$1"
    
    detect_shell_config
    
    if grep -q "$path_dir" "$SHELL_CONFIG" 2>/dev/null; then
        warning "PATH already contains $path_dir in $SHELL_CONFIG"
        return 0
    fi
    
    case "$SHELL_NAME" in
        fish)
            printf '\n# go-no-telemetry\nset -gx PATH %s $PATH\n' "$path_dir" >> "$SHELL_CONFIG"
            ;;
        *)
            printf '\n# go-no-telemetry\nexport PATH="%s:$PATH"\n' "$path_dir" >> "$SHELL_CONFIG"
            ;;
    esac
}

# Cleanup
cleanup() {
    # Only cleanup temp dir if we created it (which we don't anymore)
    # But keep this function for any future cleanup needs
    :
}

trap cleanup EXIT

read_input() {
    if [ -t 0 ] && [ -t 1 ]; then
        read -r "$@"
    else
        read -r "$@" < /dev/tty
    fi
}

# Main menu
main_menu() {
    printf "\n${BOLD}${CYAN}=== Go No Telemetry Installer ===${NC}\n\n"

    check_command git
    check_command gcc
    check_bootstrap_go
    detect_sudo

    if ! check_root; then
        info "Running as regular user (will use $SUDO_CMD when needed)"
    else
        info "Running as root"
    fi

    # Branch selection
    printf "\n${BOLD}Available Branches:${NC}\n"
    printf "1) master (latest development version)\n"
    printf "2) no-telemetry-go1.24.10 (stable go1.24.10)\n"
    printf "3) Custom branch\n"
    printf "\nSelect branch [1-3]: "
    read_input branch_choice

    case "$branch_choice" in
        1)
            BRANCH="$DEFAULT_BRANCH"
            ;;
        2)
            BRANCH="no-telemetry-go1.24.10"
            ;;
        3)
            printf "Enter branch name: "
            read_input BRANCH
            if [ -z "$BRANCH" ]; then
                BRANCH="$DEFAULT_BRANCH"
            fi
            ;;
        *)
            BRANCH="$DEFAULT_BRANCH"
            ;;
    esac

    clone_repo "$BRANCH"

    printf "\n${BOLD}Installation Options:${NC}\n"
    printf "1) Build (without tests) and install\n"
    printf "2) Build (with tests) and install\n"
    printf "3) Exit\n"
    printf "\nSelect option [1-3]: "
    read_input choice
    
    case "$choice" in
        1)
            build_go "no"
            install_menu
            ;;
        2)
            build_go "yes"
            install_menu
            ;;
        3)
            info "Exiting..."
            exit 0
            ;;
        *)
            error "Invalid option"
            ;;
    esac
}

# Install menu
install_menu() {
    printf "\n${BOLD}Installation Location:${NC}\n"
    printf "1) Override system Go ($DEFAULT_SYSTEM_GO_DIR)\n"
    printf "2) Install to custom directory (add to PATH)\n"
    printf "3) Install with renamed binaries\n"
    printf "4) Skip installation (build only)\n"
    printf "\nSelect option [1-4]: "
    read_input install_choice
    
    case "$install_choice" in
        1)
            printf "\n${YELLOW}This will override your current Go installation.${NC}\n"
            printf "Continue? [y/N]: "
            read_input confirm
            if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
                install_system "" "yes"
            else
                install_menu
            fi
            ;;
        2)
            printf "Enter installation directory [$DEFAULT_INSTALL_DIR]: "
            read_input custom_dir
            if [ -z "$custom_dir" ]; then
                custom_dir="$DEFAULT_INSTALL_DIR"
            fi
            install_system "$custom_dir" "no"
            ;;
        3)
            printf "Enter installation directory [$DEFAULT_INSTALL_DIR]: "
            read_input custom_dir
            if [ -z "$custom_dir" ]; then
                custom_dir="$DEFAULT_INSTALL_DIR"
            fi
            printf "Enter name for 'go' binary [gotelemetry]: "
            read_input go_name
            if [ -z "$go_name" ]; then
                go_name="gotelemetry"
            fi
            printf "Enter name for 'gofmt' binary [gofmttelemetry]: "
            read_input gofmt_name
            if [ -z "$gofmt_name" ]; then
                gofmt_name="gofmttelemetry"
            fi
            install_renamed "$custom_dir" "$go_name" "$gofmt_name"
            ;;
        4)
            info "Skipping installation. Binaries are in $REPO_DIR/bin"
            ;;
        *)
            error "Invalid option"
            ;;
    esac
    
    printf "\n${GREEN}${BOLD}Installation complete!${NC}\n"
    if [ -f "$REPO_DIR/bin/go" ]; then
        printf "\nTesting installation...\n"
        "$REPO_DIR/bin/go" version
    fi
}

# Run main
main_menu