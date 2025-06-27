#!/bin/bash

if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit 1
fi

USERNAME="tunnel"
SSHD_CONFIG="/etc/ssh/sshd_config"
RC_SCRIPT="/usr/local/bin/serveo-fake-shell"

# Delete user if it already exists
if id "$USERNAME" &>/dev/null; then
  echo "[!] sadly '$USERNAME' already exists. Removing..."
  userdel -r "$USERNAME" 2>/dev/null
  rm -rf /home/$USERNAME
fi

clear
echo ""
echo "====================================================="
echo " Host your own serveo alternative"
echo " GitHub: https://github.com/zack1919/zackserveo"
echo " Please star the repo :P"
echo " Honourable mentions: http://myvpscommunity.xyz/"
echo "====================================================="
echo ""
echo "Disclaimer: This tool is provided as-is. The author is not responsible"
echo "for misuse, abuse, or any illegal activity conducted through this system."
echo ""

read -p "Do you want to continue setup? [y/N]: " confirm
[[ "$confirm" != "y" && "$confirm" != "Y" ]] && exit 1
PASSWORD=$(openssl rand -base64 12)

useradd -m -s /bin/bash "$USERNAME"
echo "$USERNAME:$PASSWORD" | chpasswd
usermod -aG sudo "$USERNAME"

sed -i 's/#\?AllowTcpForwarding.*/AllowTcpForwarding yes/' "$SSHD_CONFIG"
sed -i 's/#\?GatewayPorts.*/GatewayPorts yes/' "$SSHD_CONFIG"
sed -i 's/#\?PermitOpen.*/PermitOpen any/' "$SSHD_CONFIG"

if ! grep -q "Match User $USERNAME" "$SSHD_CONFIG"; then
cat <<EOF >> "$SSHD_CONFIG"

Match User $USERNAME
    ForceCommand $RC_SCRIPT
    PermitTTY yes
    AllowTcpForwarding yes
    GatewayPorts yes
EOF
fi

cat <<'EOF' > "$RC_SCRIPT"
#!/bin/bash

trap 'echo ""; echo "SIGINT received. Closing session..."; exit 130' SIGINT

IP=$(hostname -I | awk '{print $1}')

# Extract port mappings from SSH_ORIGINAL_COMMAND
if [[ -n "$SSH_ORIGINAL_COMMAND" ]]; then
    echo ""
    echo "Detected forwarded ports:"
    echo "$SSH_ORIGINAL_COMMAND" | grep -oE '(-R|--remote)[= ]?[0-9]+:localhost:[0-9]+' | while read line; do
        REMOTE=$(echo "$line" | sed -E 's/.*([0-9]+):localhost:([0-9]+)/\1 \2/')
        REMOTE_PORT=$(echo "$REMOTE" | awk '{print $1}')
        LOCAL_PORT=$(echo "$REMOTE" | awk '{print $2}')
        echo "Forwarding TCP connections from $IP:$REMOTE_PORT -> localhost:$LOCAL_PORT"
    done
else
    echo "Successfully forwarding the ports. You have 4958658383848328294892834 seconds to escape the backrooms. Good luck buddy!"
fi

while true; do
  sleep 4958658383848328294892834
done
EOF

chmod +x "$RC_SCRIPT"

systemctl restart sshd

IP=$(curl -s ifconfig.me || curl -s icanhazip.com || wget -qO- ifconfig.me)

clear
echo ""
echo "====================================================="
echo " Your VPS now acts as a serveo.net alternative"
echo ""
echo " You can access local ports globally without the needing to port forward by using:"
echo ""
echo "   ssh -R <remote-port>:localhost:<local-port> $USERNAME@$IP"
echo ""
echo " Example:"
echo "   ssh -R 8080:localhost:80 $USERNAME@$IP"
echo ""
echo " Then access your service/port via: http://$IP:8080 (again this is an example)"
echo ""
echo " Login credentials: (change password if you wanna)"
echo "   Username: $USERNAME"
echo "   Password: $PASSWORD"
echo ""
echo "====================================================="
