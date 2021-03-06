#!/bin/sh
# startup.sh

SONAR_VERSION=7.9
SONARQUBE_HOME=/opt/sonarqube
FLUTTER_HOME=/opt/flutter

# Install Git
apk add git curl

# Download SonarQube and put it into an ephemeral folder
echo "get sonarqube"
wget -O /tmp/sonarqube.zip https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-$SONAR_VERSION.zip
mkdir -p /home/sonarqube
rm -rf $SONARQUBE_HOME
ln -s /home/sonarqube $SONARQUBE_HOME
unzip /tmp/sonarqube.zip -d /tmp/
mv -f /tmp/sonarqube-$SONAR_VERSION/* $SONARQUBE_HOME/
rm -rf /tmp/sonarqube-$SONAR_VERSION/
chmod 0777 -R $SONARQUBE_HOME
echo "done sonar"

# Download Flutter and stuff 
echo "get flutter and dart"
wget -O /tmp/flutter.tar.xz https://storage.googleapis.com/flutter_infra/releases/stable/linux/flutter_linux_1.22.5-stable.tar.xz
tar -xf /tmp/flutter.tar.xz -C /opt/
rm -rf /tmp/flutter.tar.xz
chmod 0777 -R $FLUTTER_HOME
export PATH="$FLUTTER_HOME/bin:$FLUTTER_HOME/bin/cache/dart-sdk/bin:${PATH}"
#flutter doctor

# Workaround for ElasticSearch
echo "get elastic"
adduser -DH elasticsearch
echo "su - elasticsearch -c '/bin/sh /home/site/wwwroot/elasticsearch.sh'" > $SONARQUBE_HOME/elasticsearch/bin/elasticsearch

# Install any plugins
echo "sonar plugins"
cd $SONARQUBE_HOME/extensions/plugins
if [ ! -f sonar-auth-aad-plugin-1.1.jar ]; then
    wget https://github.com/hkamel/sonar-auth-aad/releases/download/1.1/sonar-auth-aad-plugin-1.1.jar
fi
if [ ! -f sonar-flutter-plugin-0.3.1.jar ]; then
    wget https://github.com/insideapp-oss/sonar-flutter/releases/download/0.3.1/sonar-flutter-plugin-0.3.1.jar
fi

# Start the server
echo "sonar start"
cd $SONARQUBE_HOME
exec java -jar lib/sonar-application-$SONAR_VERSION.jar \
  -Dsonar.log.console=true \
  -Dsonar.jdbc.username="$SONARQUBE_JDBC_USERNAME" \
  -Dsonar.jdbc.password="$SONARQUBE_JDBC_PASSWORD" \
  -Dsonar.jdbc.url="$SONARQUBE_JDBC_URL" \
  -Dsonar.web.port="$WEBSITES_PORT" \
  -Dsonar.web.javaAdditionalOpts="$SONARQUBE_WEB_JVM_OPTS -Djava.security.egd=file:/dev/./urandom" \
  -Dsonar.core.serverBaseURL="https://$WEBSITE_HOSTNAME" \
  -Dsonar.auth.aad.enabled="$SONARQUBE_AUTH_AAD_ENABLED" \
  -Dsonar.auth.aad.clientId.secured="$SONARQUBE_AUTH_AAD_CLIENTID" \
  -Dsonar.auth.aad.clientSecret.secured="$SONARQUBE_AUTH_AAD_CLIENTSECRET" \
  -Dsonar.auth.aad.tenantId="$SONARQUBE_AUTH_AAD_TENANTID" \
  -Dsonar.auth.aad.allowUsersToSignUp="true" \
  -Dsonar.auth.aad.loginStrategy="Same as Azure AD login" \
