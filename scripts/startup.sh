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


if [ ! -f /root/config.json ]; then
    cat >/root/config.json <<EOL
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

echo ""
cat /app/config.json
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

if [ -f /var/tmp/sshconf ]; then
    echo " >> Copying host ssh config from /var/tmp/sshconf to /root/.ssh/config"
    cp /var/tmp/sshconf /root/.ssh/config
fi

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

echo " >> Copying host ssh key from /var/tmp/id to /root/.ssh/id_rsa"
cp /var/tmp/id /root/.ssh/id_rsa
chmod 600 /root/.ssh/id_rsa

chmod 600 /root/.ssh/id_rsa

echo " >> Building Satis for the first time"
scripts/build.sh

if [[ $CRONTAB_FREQUENCY == -1 ]]; then
  echo " > No Cron"
else
  echo " > Crontab frequency set to: ${CRONTAB_FREQUENCY}"
  sed -i "s/${DEFAULT_CRONTAB_FREQUENCY_ESCAPED}/${CRONTAB_FREQUENCY_ESCAPED}/g" /etc/cron.d/satis-cron
fi

# Copy custom config if exists
[[ -f /app/config.php ]] && cp /app/config.php  /satisfy/app/config.php


exit 0
