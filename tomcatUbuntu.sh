#!/bin/bash
set -e

# === Remove old Tomcat if exists ===
echo ">>> Removing old Tomcat installation..."
sudo systemctl stop tomcat 2>/dev/null || true
sudo systemctl disable tomcat 2>/dev/null || true
sudo rm -rf /opt/tomcat
sudo rm -f /etc/systemd/system/tomcat.service

# === Update system and install Java ===
echo ">>> Installing Java..."
sudo apt update -y
sudo apt install openjdk-17-jre-headless wget -y

# === Download Tomcat 9.0.109 ===
echo ">>> Downloading Tomcat..."
cd /tmp
wget https://dlcdn.apache.org/tomcat/tomcat-9/v9.0.109/bin/apache-tomcat-9.0.109.tar.gz

# === Extract and move to /opt ===
sudo tar -zxvf apache-tomcat-9.0.109.tar.gz -C /opt/
sudo mv /opt/apache-tomcat-9.0.109 /opt/tomcat

# === Create Tomcat group and user ===
echo ">>> Creating Tomcat user..."
sudo groupadd -f tomcat
id -u tomcat &>/dev/null || sudo useradd -s /bin/false -g tomcat -d /opt/tomcat tomcat

# === Set permissions ===
sudo chown -R tomcat:tomcat /opt/tomcat

# === Configure Manager User ===
TOMCAT_USER="tomcat"
TOMCAT_PASS="raham123"

sudo tee /opt/tomcat/conf/tomcat-users.xml > /dev/null <<EOF
<tomcat-users>
    <role rolename="manager-gui"/>
    <role rolename="manager-script"/>
    <user username="$TOMCAT_USER" password="$TOMCAT_PASS" roles="manager-gui,manager-script"/>
</tomcat-users>
EOF

# Allow Manager access from any IP
sudo sed -i '/<Context>/a <Valve className="org.apache.catalina.valves.RemoteAddrValve" allow=".*" />' \
    /opt/tomcat/webapps/manager/META-INF/context.xml

# === Create systemd service ===
cat <<EOF | sudo tee /etc/systemd/system/tomcat.service
[Unit]
Description=Apache Tomcat Web Application Container
After=network.target

[Service]
Type=forking

User=tomcat
Group=tomcat

Environment="JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64"
Environment="CATALINA_HOME=/opt/tomcat"

ExecStart=/opt/tomcat/bin/startup.sh
ExecStop=/opt/tomcat/bin/shutdown.sh

Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

# === Start Tomcat service ===
sudo systemctl daemon-reload
sudo systemctl enable tomcat
sudo systemctl start tomcat

# === Show status ===
sudo systemctl status tomcat --no-pager

# === Print login info ===
IP=$(hostname -I | awk '{print $1}')
echo ""
echo "✅ Tomcat Installation Complete!"
echo "Login URL: http://$IP:8080/manager/html"
echo "Username: $TOMCAT_USER"
echo "Password: $TOMCAT_PASS"
echo ""
