#!/bin/bash
FILEPATH=/var/tmp
SCRIPTLOC=/var/scripts/letsencrypt
DNSNAME=github.falaconsulting.be

echo "Starting the certificate change..."
echo -n "Password to connect to Github Enterprise Admin: "
read -s password
echo

echo "Cleaning the repository..."
rm -rf $SCRIPTLOC/certs/$DNSNAME/*

echo "Getting a new certificate from Let's Encrypt for the Github server..."
dehydrated -c -d "$DNSNAME alambic.$DNSNAME assets.$DNSNAME avatars.$DNSNAME codeload.$DNSNAME gist.$DNSNAME pages.$DNSNAME render.$DNSNAME reply.$DNSNAME uploads.$DNSNAME raw.$DNSNAME media.$DNSNAME" --config $SCRIPTLOC/letsencrypt-azuredns-hook/config.sh -k $SCRIPTLOC/letsencrypt-azuredns-hook/azure.hook.sh

echo "Getting the setting file from Github..."
curl -L 'https://api_key:'$password'@'$DNSNAME':8443/setup/api/settings' >> $FILEPATH/settings.json
PUBLICCERT=$(cat $SCRIPTLOC/certs/$DNSNAME/fullchain.pem)

echo "Replacing the certificate..."
cat $FILEPATH/settings.json | jq -r ".enterprise.github_ssl.cert = \"$PUBLICCERT\"" > $FILEPATH/settings2.json
rm -rf $FILEPATH/settings.json
PRIVATEKEY=$(cat $SCRIPTLOC/certs/$DNSNAME/privkey.pem)

echo "Replacing the Private Key..."
cat $FILEPATH/settings2.json | jq -r ".enterprise.github_ssl.key = \"$PRIVATEKEY\"" > $FILEPATH/settings.json
rm -rf $FILEPATH/settings2.json

echo "Uploading the new configuration file..."
curl -L -X PUT 'https://api_key:'$password'@'$DNSNAME':8443/setup/api/settings' --data-urlencode "settings=`cat $FILEPATH/settings.json`"
rm -rf $FILEPATH/settings.json

echo "The certificate has been changed correctly"