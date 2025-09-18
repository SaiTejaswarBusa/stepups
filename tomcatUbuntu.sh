#!/bin/bash
sudo apt update -y
sudo apt install openjdk-17-jre-headless wget -y

TOMCAT_VERSION=9.0.109
TOMCAT_DIR=apache-tomcat-$TOMCAT_VERSION
TOMCAT_ARCHIVE=${TOMCAT_DIR}.tar.gz
DOWNLOAD_URL=https://dlcdn.apache.org/tomcat/tomcat-9/v${TOMCAT_VERSION}/bin/${TOMCAT_ARCHIVE}
INSTALL_DIR=/opt/tomcat
wget ${DOWNLOAD_URL}
sudo mkdir -p $INSTALL_DIR
sudo tar -zxvf ${TOMCAT_ARCHIVE} -C $INSTALL_DIR
sudo ln -s $INSTALL_DIR/$TOMCAT_DIR $INSTALL_DIR/latest
sudo groupadd --system tomcat
sudo useradd -s /bin/false -g tomcat -d $INSTALL_DIR/latest tomcat
sudo chown -R tomcat:tomcat $INSTALL_DIR
sudo cp $INSTALL_DIR/latest/conf/tomcat-users.xml $INSTALL_DIR/latest/conf/tomcat-users.xml.bak
sudo sed -i '/<\/tomcat-users>/ i\<role rolename="manager-gui"/>' $INSTALL_DIR/latest/conf/tomcat-users.xml
sudo sed -i '/<\/tomcat-users>/ i\<role rolename="manager-script"/>' $INSTALL_DIR/latest/conf/tomcat-users.xml
sudo sed -i '/<\/tomcat-users>/ i\<user username="tomcat" password="sai123" roles="manager-gui,manager-script"/>' $INSTALL_DIR/latest/conf/tomcat-users.xml
sudo cp $INSTALL_DIR/latest/webapps/manager/META-INF/context.xml $INSTALL_DIR/latest/webapps/manager/META-INF/context.xml.bak
sudo sed -i '/Valve className="org.apache.catalina.valves.RemoteAddrValve"/d' $INSTALL_DIR/latest/webapps/manager/META-INF/context.xml
SERVICE_FILE=/etc/systemd/system/tomcat.service
sudo bash -c "cat > $SERVICE_FILE" <<EOL
[Unit]
Description=Apache Tomcat Web Application Container
After=network.target
[Service]
Type=forking
User=tomcat
Group=tomcat
Environment=JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
Environment=CATALINA_PID=$INSTALL_DIR/latest/temp/tomcat.pid
Environment=CATALINA_HOME=$INSTALL_DIR/latest
Environment=CATALINA_BASE=$INSTALL_DIR/latest
Environment='CATALINA_OPTS=-Xms512M -Xmx1024M -server -XX:+UseParallelGC'
Environment='JAVA_OPTS=-Djava.awt.headless=true -Djava.security.egd=file:/dev/./urandom'
ExecStart=$INSTALL_DIR/latest/bin/startup.sh
ExecStop=$INSTALL_DIR/latest/bin/shutdown.sh
Restart=on-failure
[Install]
WantedBy=multi-user.target
EOL
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable tomcat
sudo systemctl start tomcat
