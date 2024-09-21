#!/usr/bin/env bash

# Color and symbol configuration for logs
setup_colors() {
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
  dash="${purpleColor}-${endColor}"
  double_dash="${turquoiseColor}--${endColor}"
  open_bracket="${purpleColor}[${endColor}"
  close_bracket="${purpleColor}]${endColor}"
  double_dot="${turquoiseColor}:${endColor}"
  open_angle="${purpleColor}<${endColor}"
  close_angle="${purpleColor}>${endColor}"
  double_colon="${turquoiseColor}::${endColor}"
}

setup_colors

# Function to handle errors and events
log_message() {
  local log_file="/var/log/autoip/autoip.log"
  local level=$1
  local message=$2
  local timestamp=$(date +"%Y-%m-%d %H:%M:%S")

  # Save the message in the log file
  echo "${timestamp} ${level} ${message}" >> "$log_file"

  # Show the message on standard output
  case "$level" in
    ERROR)
      echo -e "${error} ${message}"
      ;;
    WARNING)
      echo -e "${warning} ${message}"
      ;;
    INFO)
      echo -e "${plus} ${message}"
      ;;
    *)
      echo -e "${plus} ${message}"
      ;;
  esac
}

# Function to validate if the content is an IP
validate_ip() {
  local ip="$1"
  [[ "$ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]
}

# Function to update the IP in NO-IP
update_noip() {
  local current_ip_file="/tmp/autoip"

  if [[ -s "$current_ip_file" ]]; then
    local current_ip=$(cat "$current_ip_file")
  else
    log_message "WARNING" "Current IP not found or the file is empty."
    return 1
  fi

  if validate_ip "$current_ip"; then
    response=$(curl -s -X GET "http://dynupdate.no-ip.com/nic/update?hostname=${hostname}&myip=${current_ip}" -u "${user}:${password}" -H "User-Agent: ${user_agent}")

    # List of possible responses with their log levels and associated messages
    declare -A responses=(
      ["good"]="INFO: DNS hostname updated successfully: ${response}"
      ["nochg"]="INFO: The IP is current, no update performed: ${response}"
      ["nohost"]="ERROR: The hostname does not exist under the specified account."
      ["badauth"]="ERROR: Invalid username and password combination."
      ["badagent"]="ERROR: Client disabled. No further updates should be made without user intervention."
      ["!donator"]="ERROR: Attempted to use a feature not available to the user."
      ["abuse"]="ERROR: Username blocked due to abuse. Updates halted."
      ["911"]="ERROR: Fatal error at No-IP. Retry no sooner than 30 minutes."
    )

    # Flags to find a match
    found=false

    # Search the list of possible responses
    for key in "${!responses[@]}"; do
      if echo "$response" | grep -q "^$key"; then
        # Extract level and message from the array value
        IFS=':' read -r level message <<< "${responses[$key]}"
        log_message "$level" "$message"
        found=true
        break
      fi
    done

    # Message for unexpected responses
    if [[ "$found" == false ]]; then
      log_message "WARNING" "Unexpected response from the server: ${response}"
    fi
  else
    log_message "WARNING" "The IP ${current_ip} is invalid."
    return 1
  fi
}

# Function to read configuration from a TOML file
read_configuration() {
  local config_file="$1"

  hostname=$(tq -f "$config_file" noip.hostname)
  user=$(tq -f "$config_file" noip.user)
  password=$(tq -f "$config_file" noip.password)
  user_agent=$(tq -f "$config_file" noip.user_agent)

  log_message "INFO" "Configuration loaded from ${config_file}."
}

config_file="/usr/local/etc/autoip/config.toml"
read_configuration "$config_file"

# Function to get the IP and update if it has changed
get_ip() {
  #local no_station="test" # testing

  #if [[ -z "$no_station" ]]; then
    #log_message "WARNING" "Could not obtain the station number."
  #fi

  servers=(
    #"localhost:5000/?station=${no_station}"  # testing
    "api.ipify.org"
    "icanhazip.com"
    "ifconfig.me"
    "wtfismyip.com/text"
  )

  local current_ip_file="/tmp/autoip"
  local temp_ip_file="/tmp/autoip-temp"
  local old_ip_file="/tmp/autoip-old"

  local ip

  for server in "${servers[@]}"; do
    ip=$(curl -sL "$server" | grep -Eo '((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)')
    
    if [[ -n "$ip" ]]; then
        echo "$ip" > "$temp_ip_file"
        log_message "INFO" "IP obtained from ${server}: ${ip}"
        break
    else
        log_message "ERROR" "Could not obtain a valid IP from ${server}."
    fi
  done

  if [[ -s "$temp_ip_file" ]]; then
      local new_ip=$(cat "$temp_ip_file")
      local current_ip=""

      if [[ -s "$current_ip_file" ]]; then
          current_ip=$(cat "$current_ip_file")
      fi

      if validate_ip "$new_ip" && [[ "$new_ip" != "$current_ip" ]]; then
          if validate_ip "$current_ip"; then
              echo "$current_ip" > "$old_ip_file"
          fi

          echo "$new_ip" > "$current_ip_file"
          log_message "INFO" "IP updated: ${new_ip}"
          update_noip
      else
        log_message "INFO" "The IP has not changed."
      fi

      rm -f "$temp_ip_file"
  fi
}

get_ip
