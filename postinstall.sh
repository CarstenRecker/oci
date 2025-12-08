#!/bin/bash
# Check if script is run as root
if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi
# Ask the user if they want to install Docker
read -p "Do you want to install Docker (Y/n)? " docker_answer
# Ask the user if they want to open any ports
read -p "Do you want to open any ports (Y/n)? " ports_answer
if [[ ${ports_answer:0:1} == "y" || ${ports_answer:0:1} == "Y" ]]; then
    read -p "Enter the port numbers you want to open, separated by commas: " ports
fi
# Ask the user if they want to reboot
read -p "Do you want to reboot the system now (Y/n)? " reboot_answer
# Set restart of services to automatic, when using apt
# Check if needrestart is installed
if dpkg -l | grep needrestart > /dev/null; then
    # Change the configuration
    sed -i "s/#\$nrconf{restart} = 'i';/\$nrconf{restart} = 'a';/g" /etc/needrestart/needrestart.conf
else
    echo "needrestart is not installed."
fi
# Update the OS
apt-get update -y
apt-get upgrade -y
# Install packages
apt-get install -y ca-certificates curl gnupg net-tools dnsutils
# Set timezone to Europe/Berlin
timedatectl set-timezone Europe/Berlin
# Install Docker if requested
case ${docker_answer:0:1} in
    y|Y )
        echo "Installing Docker..."
        # Add Docker's official GPG key
        install -m 0755 -d /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        chmod a+r /etc/apt/keyrings/docker.gpg
        echo \
          "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
          "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
          tee /etc/apt/sources.list.d/docker.list > /dev/null

        # Update the apt package index
        apt-get update -y

        # Install Docker
        apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    ;;
    * )
        echo "Docker will not be installed."
    ;;
esac
# Open ports if requested
case ${ports_answer:0:1} in
    y|Y )
        # Install iptables-persistent
        apt-get install -y iptables-persistent

        IFS=',' read -ra ADDR <<< "$ports"
        for port in "${ADDR[@]}"; do
            iptables -A INPUT -p tcp --dport $port -j ACCEPT
            echo "Port $port is now open."
        done

        # Save the current iptables rules
        iptables-save > /etc/iptables/rules.v4
    ;;
    * )
        echo "No ports will be opened."
    ;;
esac
# Reboot if requested
case ${reboot_answer:0:1} in
    y|Y )
        echo "The system is rebooting now..."
        reboot
    ;;
    * )
        echo "The system will not reboot."
    ;;
esac