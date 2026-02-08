#!/bin/bash
# install.sh - DM Claude Installation Script
# Sets up DM Claude with dependency checking and configuration
#
# Usage:
#   ./install.sh          Interactive installation with prompts
#   ./install.sh --auto   Non-interactive installation (core only, uses uv if available)

set -e  # Exit on error

# Parse arguments
AUTO_MODE=false
if [ "$1" = "--auto" ]; then
    AUTO_MODE=true
fi

# Color output (if terminal supports it)
if [ -t 1 ] && [ "${TERM}" != "dumb" ]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    BOLD='\033[1m'
    NC='\033[0m' # No Color
else
    RED=''; GREEN=''; YELLOW=''; BLUE=''; BOLD=''; NC=''
fi

# Helper functions
print_header() {
    echo -e "${BOLD}${BLUE}================================================${NC}"
    echo -e "${BOLD}${BLUE}        DM Claude Installation Script${NC}"
    echo -e "${BOLD}${BLUE}================================================${NC}"
    echo
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Check for required commands
check_command() {
    local cmd="$1"
    local install_msg="$2"

    if ! command -v "$cmd" >/dev/null 2>&1; then
        print_error "$cmd is not installed"
        echo "  $install_msg"
        return 1
    fi
    return 0
}

# Main installation
main() {
    print_header

    # Check OS
    OS="$(uname -s)"
    case "${OS}" in
        Linux*)     OS_TYPE="Linux";;
        Darwin*)    OS_TYPE="Mac";;
        *)          OS_TYPE="Unknown";;
    esac

    print_info "Detected OS: $OS_TYPE"
    echo

    # Check Python version
    print_info "Checking Python installation..."

    PYTHON_CMD=""
    MIN_PYTHON_VERSION="3.11"

    # Try different Python commands
    for cmd in python3 python; do
        if command -v "$cmd" >/dev/null 2>&1; then
            VERSION=$($cmd -c 'import sys; print(".".join(map(str, sys.version_info[:2])))')
            if [ "$(printf '%s\n' "$MIN_PYTHON_VERSION" "$VERSION" | sort -V | head -n1)" = "$MIN_PYTHON_VERSION" ]; then
                PYTHON_CMD="$cmd"
                print_success "Found Python $VERSION at $(which $cmd)"
                break
            else
                print_warning "$cmd version $VERSION is below minimum required $MIN_PYTHON_VERSION"
            fi
        fi
    done

    if [ -z "$PYTHON_CMD" ]; then
        print_error "Python $MIN_PYTHON_VERSION or higher is required but not found"
        echo "  Please install Python from: https://www.python.org/downloads/"
        exit 1
    fi
    echo

    # Check for package manager preference
    print_info "Checking for Python package manager..."

    USE_UV=false
    if command -v uv >/dev/null 2>&1; then
        print_success "Found uv (recommended)"
        if [ "$AUTO_MODE" = true ]; then
            USE_UV=true
        else
            echo -n "Use uv for installation? (recommended) [Y/n]: "
            read -r response
            if [[ ! "$response" =~ ^[Nn]$ ]]; then
                USE_UV=true
            fi
        fi
    else
        print_info "uv not found. Using pip for installation."
        print_info "For faster installation, consider installing uv: https://docs.astral.sh/uv/"
    fi
    echo

    # Select installation type
    EXTRAS=""
    INSTALL_TYPE=""

    if [ "$AUTO_MODE" = true ]; then
        # Auto mode: core only, no prompts
        print_info "Auto mode: installing core dependencies"
    else
        print_info "Select installation type:"
        echo "  1) Core only (basic DM tools)"
        echo "  2) Core + Documents (PDF processing)"
        echo "  3) Full installation (all features)"
        echo "  4) Development (includes testing tools)"
        echo
        echo -n "Enter choice [1-4] (default: 1): "
        read -r INSTALL_TYPE

        case "$INSTALL_TYPE" in
            2) EXTRAS="[docs]";;
            3) EXTRAS="[full]";;
            4) EXTRAS="[full,dev]";;
            *) EXTRAS="";;  # Default to core only
        esac
    fi
    echo

    # Create virtual environment if it doesn't exist
    if [ ! -d ".venv" ]; then
        print_info "Creating virtual environment..."
        $PYTHON_CMD -m venv .venv
        print_success "Virtual environment created"
    else
        print_info "Virtual environment already exists"
    fi
    echo

    # Install dependencies
    print_info "Installing dependencies..."

    if [ "$USE_UV" = true ]; then
        if [ -z "$EXTRAS" ]; then
            uv pip install -e .
        else
            uv pip install -e ".${EXTRAS}"
        fi
    else
        # Activate virtual environment for pip
        source .venv/bin/activate
        pip install --upgrade pip

        if [ -z "$EXTRAS" ]; then
            pip install -e .
        else
            pip install -e ".${EXTRAS}"
        fi
    fi

    print_success "Dependencies installed"
    echo

    # Create .env file if it doesn't exist
    if [ ! -f ".env" ]; then
        print_info "Creating .env file..."
        cat > .env << 'EOF'
# DM Claude Configuration

# Campaign Settings
DEFAULT_CAMPAIGN_NAME="My Campaign"
DEFAULT_STARTING_LOCATION="Thornwick"

# Optional: Discord webhook for session logging
# DISCORD_WEBHOOK_URL=https://discord.com/api/webhooks/...
EOF
        print_success ".env file created"
    else
        print_info ".env file already exists"
    fi
    echo

    # Initialize world state
    print_info "Initializing world state..."
    source tools/common.sh
    print_success "World state initialized"
    echo

    # Make all scripts executable
    print_info "Setting script permissions..."
    chmod +x tools/*.sh
    chmod +x tools/*.py
    chmod +x lib/*.py
    chmod +x features/**/*.py 2>/dev/null || true
    print_success "Script permissions set"
    echo

    # Test installation
    print_info "Testing installation..."

    # Test dice roller
    if $PYTHON_CMD lib/dice.py "1d20" >/dev/null 2>&1; then
        print_success "Dice roller working"
    else
        print_warning "Dice roller test failed"
    fi

    # Test session script
    if bash tools/dm-session.sh status >/dev/null 2>&1; then
        print_success "Session management working"
    else
        print_warning "Session management test failed"
    fi
    echo

    # Installation complete
    print_header
    print_success "Installation complete!"
    echo
    echo "Quick Start Guide:"
    echo "  1. Start a session:      bash tools/dm-session.sh start"
    echo "  2. Create an NPC:        bash tools/dm-npc.sh create \"Name\" \"description\" \"attitude\""
    echo "  3. Roll dice:            uv run python lib/dice.py 1d20+5"
    echo "  4. Search world:         bash tools/dm-search.sh \"query\""
    echo "  5. Get help:             cat README.md"
    echo

    if [ "$USE_UV" = true ]; then
        echo "You're using uv. All Python scripts should be run with: uv run python"
    else
        echo "Remember to activate the virtual environment before running Python scripts:"
        echo "  source .venv/bin/activate"
    fi
    echo

    if [ -n "$EXTRAS" ]; then
        case "$INSTALL_TYPE" in
            2) echo "Document processing features installed.";;
            3) echo "Full installation complete with all features.";;
            4) echo "Development environment ready.";;
        esac
    fi
    echo
    print_info "For more information, see README.md"
}

# Run main installation
main "$@"
