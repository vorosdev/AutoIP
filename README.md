# AutoIP

AutoIP is a Bash script that automatically updates the public IP address in the No-IP 
dynamic DNS service. It was created as an alternative to Dynamic Update Clients (DUC) 
or Dynamic DNS Clients that don't support legacy or incompatible systems.

## Requirements

- `curl`: To make HTTP requests.
- `cron`: To automate the script execution.
- `bash 4 or higher`: To run the script. If you have an older version, such as bash 3, apply the patch.

## Installation

1. Clone this repository.
2. Navigate to the repository directory.
3. Run `./setup.sh install` with administrator privileges.
4. Edit the configuration file with your credentials: `/usr/local/etc/autoip/config.toml`.

   ```toml
   noip.hostname = "your_hostname"
   noip.user = "your_username"
   noip.password = "your_password"
   noip.user_agent = "AutoIP script/debian-12.6 user1@test.com"
   ```

Note: If your version of bash is lower than 4, you need to apply the `autoip-bash3.patch`
to `autoip.sh` before executing step 3.

```
patch autoip.sh < autoip-bash3.patch
```

## Usage

The script will automatically run every 5 minutes using a cron job.

1. Run the script:

   ```bash
   ./autoip.sh
   ```

2. The script will retrieve the public IP from several servers and update it on No-IP if it has changed.

## Features

- **Colors and logs:** Uses colors to highlight messages in the console and logs events to a log file.
- **IP validation:** Ensures the retrieved IP is valid before updating it on No-IP.
- **Error handling:** Logs different types of messages (INFO, WARNING, ERROR) based on the response from the No-IP server.

## Contributions

Contributions are welcome. If you want to improve the script, feel free to open an issue or a pull request.

## License

This project is licensed under the GPLv3. It also includes MIT-licensed binaries from the [tomlq](https://github.com/cryptaliagy/tomlq) project.
