#!/bin/bash
set -e  # Exit immediately if a command exits with a non-zero status

# run as root

# don't forget to change these variables if needed and also run "sudo chmod +x install-service.sh"
SOURCE_EXECUTABLE_FILE="target/release/razer-naga-key-remap"
SOURCE_CONFIG_FILE="config/razer-naga-remap-config.toml"
TARGET_EXECUTABLE_FILE="/usr/bin/razer-naga-key-remap"
TARGET_CONFIG_FILE="/etc/razer-naga-remap-config.toml"

SERVICE_NAME="razer-naga-key-remap.service"
SERVICE_PATH="/etc/systemd/system/"


# Function to copy files with overwrite confirmation
copy_with_confirmation() {
    local src="$1"
    local dest="$2"

    if [ -e "$dest" ]; then
        read -p "$dest already exists. Do you want to overwrite it? (y/n): " choice
        case "$choice" in
            y|Y ) 
                echo "Overwriting $dest."
                cp "$src" "$dest"
                ;;
            n|N ) 
                echo "Skipping $dest."
                return 1  # Indicate that the copy was skipped
                ;;
            * ) 
                echo "Invalid choice. Skipping $dest."
                return 1  # Indicate that the copy was skipped
                ;;
        esac
    else
        cp "$src" "$dest"
    fi
}
# Function to create the systemd service file
create_service_file() {
    local service_file="$1"
    local executable="$2"
    local config="$3"

    cat <<EOF | sudo tee "$service_file" > /dev/null
[Unit]
Description=Remap for Razer Naga keys

[Service]
Type=simple
ExecStart=$executable $config

[Install]
WantedBy=multi-user.target
EOF

    echo "Systemd service file created successfully at $service_file."
}


# Copy the executable
if copy_with_confirmation "$SOURCE_EXECUTABLE_FILE" "$TARGET_EXECUTABLE_FILE"; then
    echo "Executable copied successfully."
else
    echo "Failed to copy executable." >&2
    exit 1
fi

# Make it executeable
sudo chmod +x "$TARGET_EXECUTABLE_FILE"

# Copy the configuration file
if copy_with_confirmation "$SOURCE_CONFIG_FILE" "$TARGET_CONFIG_FILE"; then
    echo "Configuration file copied successfully."
else
    echo "Failed to copy configuration file." >&2
    exit 1
fi

# Create the systemd service file
create_service_file "$SERVICE_PATH/$SERVICE_NAME" "$TARGET_EXECUTABLE_FILE" "$TARGET_CONFIG_FILE"


# Reload systemd daemon
if sudo systemctl daemon-reload; then
    echo "Systemd daemon reloaded successfully."
else
    echo "Failed to reload systemd daemon." >&2
    exit 1
fi

# Enable the service
if sudo systemctl enable "$SERVICE_NAME"; then
    echo "Service enabled successfully."
else
    echo "Failed to enable service." >&2
    exit 1
fi

# Start the service
if sudo systemctl start "$SERVICE_NAME"; then
    echo "Service started successfully."
else
    echo "Failed to start service." >&2
    exit 1
fi

# Check the status of the service
if sudo systemctl status "$SERVICE_NAME"; then
    echo "Service status checked successfully."
else
    echo "Failed to check service status." >&2
    exit 1
fi
