# Reset
Color_Off='\033[0m'       # Text Reset

# Regular Colors
Red='\033[0;31m'          # Red
Green='\033[0;32m'        # Green
Yellow='\033[0;33m'       # Yellow

DEFAULT_CRONTAB_FREQUENCY="* * * * *"
DEFAULT_CRONTAB_FREQUENCY_ESCAPED=$(printf '%s\n' "${DEFAULT_CRONTAB_FREQUENCY}" | sed 's/[[\.*^$/]/\\&/g')

[ -z "$CRONTAB_FREQUENCY" ] && CRONTAB_FREQUENCY="$DEFAULT_CRONTAB_FREQUENCY"
CRONTAB_FREQUENCY_ESCAPED=$(printf '%s\n' "${CRONTAB_FREQUENCY}" | sed 's/[[\.*^$/]/\\&/g')


if [ ! -f /root/satis.json ]; then
    cat >/root/satis.json <<EOL
{
    "name": "ENJO Composer Packages Cache",
    "homepage": "https://satis.enjo.com.au",
    "repositories": [
    ],
    "require-all":true,
    "require-dependencies":true,
    "require-dev-dependencies":true,
    "minimum-stability":"stable"
}
EOL
fi

chown www-data:www-data /root/satis.json
ln -s /root/satis.json ./satisfy


if [ ! -f /root/packages.json ]; then
    touch /root/packages.json
    cat >/root/packages.json <<EOL
{

}
EOL
fi

chown www-data:www-data /root/packages.json
ln -s /root/packages.json ./satisfy/web/
chmod 777 /root/packaes.json

if [ ! -f /root/index.html ]; then
    touch /root/index.html
EOL
fi

chown www-data:www-data /root/index.html
ln -s /root/index.html ./satisfy/web/
chmod 777 /root/index.html


chown www-data:www-data /root/.composer -R
chmod 777 /root/.composer -R
mkdir /satisfy/web/include
chown www-data:www-data /satisfy/web/include
chown www-data:www-data /satisfy/packages.json

echo ""
cat /app/satis.json
echo ""
echo ""

if [ ! -z "$PRIVATE_REPO_DOMAIN" ]; then
  echo ""
  echo -e "$Yellow"
  echo "======================================================================"
  echo "PRIVATE_REPO_DOMAIN env var is now PRIVATE_REPO_DOMAIN_LIST !!! "
  echo "----------------------------------------------------------------------"
  echo " Or use tag 1.0.0 to stay compatible with PRIVATE_REPO_DOMAIN env var"
  echo "ypereirareis/docker-satis:1.0.0"
  echo "======================================================================"
  echo -e "$Color_Off"

  exit 1
fi

touch /root/.ssh/known_hosts

echo " >> Creating the correct known_hosts file"
for _DOMAIN in $PRIVATE_REPO_DOMAIN_LIST ; do
    IFS=':' read -a arr <<< "${_DOMAIN}"
    if [[ "${#arr[@]}" == "2" ]]; then
        port="${arr[1]}"
        ssh-keyscan -t rsa,dsa -p "${port}" ${arr[0]} >> /root/.ssh/known_hosts
    else
        ssh-keyscan -t rsa,dsa $_DOMAIN >> /root/.ssh/known_hosts
    fi
done

chmod 600 /root/.ssh/id_rsa

echo " >> Building Satis for the first time"

scripts/build.sh

if [[ $CRONTAB_FREQUENCY == -1 ]]; then
  echo " > No Cron"
else
  echo " > Crontab frequency set to: ${CRONTAB_FREQUENCY}"
  sed -i "s/${DEFAULT_CRONTAB_FREQUENCY_ESCAPED}/${CRONTAB_FREQUENCY_ESCAPED}/g" /etc/cron.d/satis-cron
fi


exit 0
