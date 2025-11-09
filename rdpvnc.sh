#!/bin/bash
# Enable RDP or VNC on Debian

echo "=== Remote Access Setup ==="
echo "1) Enable RDP (xRDP)"
echo "2) Enable VNC (TightVNC)"
read -p "Choose an option (1 or 2): " choice

sudo apt update -y

if [ "$choice" == "1" ]; then
    echo "Installing xRDP..."
    sudo apt install -y xrdp
    sudo systemctl enable xrdp
    sudo systemctl start xrdp
    sudo ufw allow 3389/tcp 2>/dev/null
    echo "RDP is enabled! Use 'mstsc' on Windows and connect to your server IP."

elif [ "$choice" == "2" ]; then
    echo "Installing TightVNC Server..."
    sudo apt install -y xfce4 xfce4-goodies tightvncserver
    echo "Setting up VNC..."
    su - $SUDO_USER -c "vncserver -kill :1 >/dev/null 2>&1 || true"
    su - $SUDO_USER -c "mkdir -p ~/.vnc && echo '#!/bin/bash
xrdb $HOME/.Xresources
startxfce4 &' > ~/.vnc/xstartup && chmod +x ~/.vnc/xstartup"
    su - $SUDO_USER -c "vncserver :1"
    sudo bash -c 'cat >/etc/systemd/system/vncserver@.service <<EOF
[Unit]
Description=VNC Server for %i
After=syslog.target network.target

[Service]
Type=forking
User=%i
PAMName=login
PIDFile=/home/%i/.vnc/%H:1.pid
ExecStart=/usr/bin/vncserver :1 -geometry 1280x800 -depth 24
ExecStop=/usr/bin/vncserver -kill :1

[Install]
WantedBy=multi-user.target
EOF'
    sudo systemctl daemon-reload
    sudo systemctl enable vncserver@${SUDO_USER}.service
    sudo systemctl start vncserver@${SUDO_USER}.service
    echo "VNC is enabled! Connect with a VNC viewer to ${HOSTNAME}:5901."

else
    echo "Invalid choice. Exiting."
    exit 1
fi

echo "Done!"
