#!/bin/bash

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check OS type
get_os() {
    case "$(uname -s)" in
        Darwin*)    echo 'macos';;
        Linux*)     echo 'linux';;
        MINGW*)     echo 'windows';;
        *)          echo 'unknown';;
    esac
}

# Function to install Homebrew on macOS
install_homebrew() {
    if ! command_exists brew; then
        echo "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
}

# Function to install a package using the appropriate package manager
install_package() {
    local package_name=$1
    local OS=$(get_os)

    echo "Installing $package_name..."

    case $OS in
        'macos')
            install_homebrew
            brew install "$package_name"
            ;;

        'linux')
            if command_exists apt-get; then
                sudo apt-get update
                sudo apt-get install -y "$package_name"
            elif command_exists dnf; then
                sudo dnf install -y "$package_name"
            elif command_exists yum; then
                sudo yum install -y "$package_name"
            else
                echo "❌ Could not determine package manager. Please install $package_name manually."
                return 1
            fi
            ;;

        'windows')
            echo "For Windows, please install $package_name manually."
            return 1
            ;;

        *)
            echo "❌ Unsupported operating system"
            return 1
            ;;
    esac

    return 0
}

# Function to verify package installation
verify_package() {
    local package_name=$1
    local verify_command=${2:-$package_name}

    if command_exists "$verify_command"; then
        echo "✅ $package_name installation successful!"
        "$verify_command" -version 2>/dev/null || "$verify_command" --version
        return 0
    else
        echo "❌ $package_name installation failed"
        return 1
    fi
}

# Declare the associative array before setting values
declare -A DEPENDENCIES
# Add dependencies with explicit key-value pairs
DEPENDENCIES=(
    ["ffmpeg"]="ffmpeg"
    ["ffprobe"]="ffprobe"
)

# Install all dependencies
install_dependencies() {
    local failed_installs=()

    # Debug output
    echo "Installing the following packages:"
    # Use proper array iteration syntax
    for key in "${!DEPENDENCIES[@]}"; do
        printf "  - %s (verified with: %s)\n" "${key}" "${DEPENDENCIES[${key}]}"
    done
    echo ""

    # Iterate over array keys
    for key in "${!DEPENDENCIES[@]}"; do
        verify_command="${DEPENDENCIES[${key}]}"

        if command_exists "$verify_command"; then
            echo "✅ ${key} is already installed"
        else
            echo "❌ ${key} is not installed. Installing now..."
            if ! install_package "${key}"; then
                failed_installs+=("${key}")
                continue
            fi
        fi

        # Verify installation
        if ! verify_package "${key}" "$verify_command"; then
            failed_installs+=("${key}")
        fi
    done

    # Report results
    if [ ${#failed_installs[@]} -eq 0 ]; then
        echo "✅ All dependencies installed successfully!"
        return 0
    else
        echo "❌ The following packages failed to install:"
        printf '%s\n' "${failed_installs[@]}"
        return 1
    fi
}

# Run the installation
install_dependencies
