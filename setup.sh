#!/usr/bin/env bash

# Stop script on errors
set -e

# Define colors and symbols
color() {
  greenColor="\e[0;32m\033[1m"
  redColor="\e[0;31m\033[1m"
  blueColor="\e[0;34m\033[1m"
  yellowColor="\e[0;33m\033[1m"
  purpleColor="\e[0;35m\033[1m"   
  turquoiseColor="\e[0;36m\033[1m"
  grayColor="\e[0;37m\033[1m"
  endColor="\033[0m\e[0m"

  plus="${greenColor}[+]${endColor}"
  error="${redColor}[x]${endColor}"
  warning="${yellowColor}[!]${endColor}"
  question="${turquoiseColor}[?]${endColor}"
  double_colon="${turquoiseColor}::${endColor}"
}

# Invoke the function to load colors and symbols
color

# Check if running as root
check_root() {
    if [[ "$EUID" -ne 0 ]]; then
        echo -e "${error} This script must be run as root. Try using 'sudo'."
        exit 1
    fi
}

# Run root check at startup
check_root

# Function to install dependencies with cargo
install_dependencies_with_cargo() {
    if command -v cargo &> /dev/null; then
        echo -e "${plus} Installing dependencies with cargo..."
        cargo install tomlq --locked
    else
        echo -e "${question} Rust is not installed. Do you want to install Rust? (y/n)"
        read -r choice

        case $choice in
            y|Y)
                echo -e "${plus} Installing Rust..."
                curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
                source "$HOME/.cargo/env" # Load the cargo environment after installation
                echo -e "${plus} Installing dependencies with cargo..."
                cargo install tomlq --locked
                sudo ln -s  $HOME/.cargo/bin/tq /usr/local/bin/tq
                ;;
            n|N)
                echo -e "${warning} Dependencies not installed. Try with legacy installation."
                ;;
            *)
                echo -e "${error} Invalid option. Exiting..."
                exit 1
                ;;
        esac
    fi
}

# Function to install dependencies in legacy mode
install_dependencies_legacy() {
  check_architecture() {
    architecture=$(uname -m)
    
    echo -e "\n${double_colon} Checking system architecture ${double_colon}\n"

    case "$architecture" in
      x86_64)
        if [[ -f ./rust/x86_64/tq ]]; then
          cp ./rust/x86_64/tq /usr/local/bin/
          chmod +x /usr/local/bin/tq
          echo -e "${plus} Copied tq for x86_64 to /usr/local/bin/"
        else
          echo -e "${error} tq file for x86_64 not found."
          exit 1
        fi
        ;;
      i686|i386)
        if [[ -f ./rust/i686/tq ]]; then
          cp ./rust/i686/tq /usr/local/bin/
          chmod +x /usr/local/bin/tq
          echo -e "${plus} Copied tq for i686 to /usr/local/bin/"
        else
          echo -e "${error} tq file for i686 not found."
          exit 1
        fi
        ;;
      *)
        echo -e "${error} Unknown architecture: $architecture"
        exit 1
        ;;
    esac
  }

  # Run architecture check function
  check_architecture
}

# Set up cron job
cron_comment="# Updates the public IP on the dynamic DNS"
cron_job="*/5 * * * * /usr/local/bin/autoip"

crontab_configure() {
    if ! command -v crontab &> /dev/null; then
        echo -e "${error} crontab is not available."
        exit 1
    fi

    current_cron=$(crontab -l 2>/dev/null || true)

    if echo "$current_cron" | grep -qF "$cron_job"; then
        echo -e "${warning} Cron job already exists. No duplicate added."
    else
        (echo "$current_cron"; echo -e "\n$cron_comment"; echo "$cron_job") | crontab -
        echo -e "${plus} Cron job added to run autoip every 5 minutes."
    fi
}

# Function to install autoip
install_autoip() {
    echo -e "${plus} Installing autoip..."
    
    # Copy the autoip.sh script
    if [[ -f ./autoip.sh ]]; then
      cp ./autoip.sh /usr/local/bin/autoip
      chmod 755 /usr/local/bin/autoip
      mkdir -p /var/log/autoip
      touch /var/log/autoip/autoip.log
      chmod 644 /var/log/autoip/autoip.log
      echo -e "${plus} Copied autoip.sh to /usr/local/bin/autoip"
    else
      echo -e "${error} autoip.sh file not found."
      exit 1
    fi

    # Create configuration directory if it doesn't exist and copy the configuration file
    config_dir="/usr/local/etc/autoip"
    if [[ ! -d "$config_dir" ]]; then
      mkdir -p "$config_dir"
      echo -e "${plus} Configuration directory created at $config_dir"
    fi

    if [[ -f ./config.toml ]]; then
      cp ./config.toml "$config_dir"
      chmod 755 -R "$config_dir"
      echo -e "${plus} config.toml file copied to $config_dir"
    else
      echo -e "${error} config.toml file not found."
      exit 1
    fi
    
    crontab_configure

    echo -e "${plus} Installation of autoip completed!"
}

# Main installation function
install() {
    echo "Select installation type:"
    echo "1) Legacy Installation (with precompiled musl tq)"
    echo "2) Installation with Cargo (with cargo tq)"
    read -p "Choose an option [1-2]: " choice

    case $choice in
        1)
            install_dependencies_legacy
            ;;
        2)
            install_dependencies_with_cargo
            ;;
        *)
            echo -e "${error} Invalid option. Exiting..."
            exit 1
            ;;
    esac

    # Install autoip after dependencies
    install_autoip
}

# Uninstallation function
uninstall() {
  if ! command -v autoip &> /dev/null; then
    echo -e "\n${double_colon} AutoIP is not installed ${double_colon}\n"
    exit 1
  fi

  # Uninstall tomlq if cargo is available
  if command -v cargo &> /dev/null; then
    if [[ -f ~/.cargo/bin/tomlq ]]; then
      cargo uninstall tomlq &> /dev/null
      echo -e "${plus} tomlq package uninstalled with cargo."
    fi
  fi

  # Remove binary files
  if [[ -f /usr/local/bin/tq ]]; then
    rm -f /usr/local/bin/tq
    echo -e "${plus} tq file removed from /usr/local/bin/"
  fi

  if [[ -f /usr/local/bin/autoip ]]; then
    rm -f /usr/local/bin/autoip
    echo -e "${plus} autoip file removed from /usr/local/bin/"
  fi

  # Remove configuration directory
  config_dir="/usr/local/etc/autoip"
  if [[ -d "$config_dir" ]]; then
    rm -rf "$config_dir"
    echo -e "${plus} Configuration directory removed at $config_dir"
  else
    echo -e "${warning} Configuration directory does not exist."
  fi

  # Remove log file
  log_file="/var/log/autoip/autoip.log"
  if [[ -f "$log_file" ]]; then
    rm -f "$log_file"
    echo -e "${plus} Log file removed at $log_file"
  fi

  # Remove cron job and comment in one step
  if crontab -l | grep -qF "$cron_job" || crontab -l | grep -qF "$cron_comment"; then
    crontab -l | grep -vF "$cron_job" | grep -vF "$cron_comment" | crontab -
    echo -e "${plus} Cron job and comment removed."
  fi

  echo -e "${plus} Uninstallation completed."
}

# Check arguments
if [[ $# -eq 0 ]]; then
    echo -e "${error} You must specify an action. Use 'install' or 'uninstall'."
    exit 1
fi

case $1 in
    install)
        install
        ;;
    uninstall)
        uninstall
        ;;
    *)
        echo -e "${error} Invalid action. Use 'install' or 'uninstall'."
        exit 1
        ;;
esac
