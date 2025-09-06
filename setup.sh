#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

echo "Starting idempotent dotfiles installation for Ubuntu..."

# Determine the directory containing this script so paths work regardless of the current working directory
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- Function Definitions ---

# Function to install APT packages from a file
install_apt_packages() {
  echo "Updating APT package list..."
  sudo apt-get update

  echo "Installing APT packages from apt.packages.txt..."
  while read -r package; do
    if [ -n "$package" ] && ! dpkg -s "$package" &> /dev/null; then
      echo "Installing missing APT package: $package"
      sudo apt-get install -y "$package"
    elif [ -n "$package" ]; then
      echo "APT package '$package' is already installed. Skipping."
    fi
  done < "$DOTFILES_DIR/apt.packages.txt"
}

setup_repositories() {
  if [ ! -f /usr/share/keyrings/regolith-archive-keyring.gpg ]; then
    wget -qO - https://archive.regolith-desktop.com/regolith.key | \
      gpg --dearmor | sudo tee /usr/share/keyrings/regolith-archive-keyring.gpg > /dev/null
  else
    echo "Regolith GPG key already exists. Skipping."
	fi


  if [ ! -f /etc/apt/sources.list.d/regolith.list ]; then
    echo "Setting up the Regolith repository..."
		echo deb "[arch=amd64 signed-by=/usr/share/keyrings/regolith-archive-keyring.gpg] \
			https://archive.regolith-desktop.com/ubuntu/stable plucky v3.3" | \
			sudo tee /etc/apt/sources.list.d/regolith.list
	else
    echo "Docker repository already configured. Skipping."
	fi

  which curl || sudo apt install curl

  echo "Configuring Docker repository..."

  # Check if Docker GPG key already exists
  if [ ! -f /usr/share/keyrings/docker-archive-keyring.gpg ]; then
    echo "Adding Docker's official GPG key..."
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
  else
    echo "Docker GPG key already exists. Skipping."
  fi

  # Check if Docker repository is already added
  if [ ! -f /etc/apt/sources.list.d/docker.list ]; then
    echo "Setting up the Docker repository..."
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update
  else
    echo "Docker repository already configured. Skipping."
  fi

}

# Function to set up Docker repository, service, and user permissions
setup_docker() {

  echo "Managing Docker service and user permissions..."

  # Check if user is already in the docker group
  if ! groups "$USER" | grep -q "docker"; then
    echo "Adding user '$USER' to the 'docker' group..."
    sudo usermod -aG docker "$USER"
    echo "You will need to log out and back in for the docker group changes to take effect."
  else
    echo "User '$USER' is already in the 'docker' group. Skipping."
  fi

  # Ensure Docker service is running and enabled
  echo "Ensuring Docker service is started and enabled..."
  sudo systemctl is-active --quiet docker || sudo systemctl start docker
  sudo systemctl is-enabled --quiet docker || sudo systemctl enable docker
}

# Function to install standard snaps from a file
install_standard_snaps() {
  echo "Installing standard Snap packages from snap.packages.txt..."
  while read -r package; do
    if [ -n "$package" ] && ! snap list | grep -q "$package"; then
      echo "Installing missing standard Snap package: $package"
      sudo snap install "$package"
    elif [ -n "$package" ]; then
      echo "Standard Snap package '$package' is already installed. Skipping."
    fi
  done < "$DOTFILES_DIR/snap.packages.txt"
}

# Function to install classic snaps from a file
install_classic_snaps() {
  echo "Installing classic Snap packages from snap.classic.packages.txt..."
  while read -r package; do
    if [ -n "$package" ] && ! snap list | grep -q "$package"; then
      echo "Installing missing classic Snap package: $package"
      sudo snap install "$package" --classic
    elif [ -n "$package" ]; then
      echo "Classic Snap package '$package' is already installed. Skipping."
    fi
  done < "$DOTFILES_DIR/snap.classic.packages.txt"
}

# Function to create symbolic links for dotfiles
symlink_dotfiles() {
  echo "Creating symbolic links for dotfiles..."
  BACKUP_DIR="$HOME/dotfiles_backup_$(date +%F)"

  # Create backup directory if it doesn't exist
  mkdir -p "$BACKUP_DIR"
  mkdir -p ~/.vim/swapfiles/

  # Items to symlink from the dotfiles repo (relative to repo root) to $HOME
  CONFIG_SYMLINKS=(
    ".config/regolith3"
    ".vimrc"
    ".bash_aliases"
  )

  for rel_path in "${CONFIG_SYMLINKS[@]}"; do
    src="$DOTFILES_DIR/$rel_path"
    dest="$HOME/$rel_path"

    # Skip if source does not exist
    if [ ! -e "$src" ] && [ ! -L "$src" ]; then
      echo "Warning: source '$src' not found. Skipping."
      continue
    fi

    # Ensure destination parent directory exists
    mkdir -p "$(dirname "$dest")"

    # Backup an existing non-symlink destination
    if [ -e "$dest" ] && [ ! -L "$dest" ]; then
      echo "Backing up existing '$dest' to '$BACKUP_DIR/'"
      mv "$dest" "$BACKUP_DIR/"
    fi

    # Create or update the symlink
    ln -sfn "$src" "$dest"
    echo "Linked '$dest' -> '$src'"
  done
}

# Function to identify and save manually installed APT packages
save_manual_packages() {
  echo "Identifying manually installed APT packages..."
  apt-mark showmanual > "$DOTFILES_DIR/manual_packages.log"
  echo "Manually installed packages saved to $DOTFILES_DIR/manual_packages.log"
}

install_tailscale() {
  which tailscale || curl -fsSL https://tailscale.com/install.sh | sh
}

# --- Main execution function ---
main() {
  setup_repositories
  install_apt_packages
  setup_docker
  install_standard_snaps
  install_classic_snaps
  install_tailscale
  symlink_dotfiles
  save_manual_packages

  echo "Dotfiles setup complete!"
  echo "Installation finished. Please log out and log back in to finalize changes (e.g., docker group membership)."
}

# Call the main function to start the script
main

