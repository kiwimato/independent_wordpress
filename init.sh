#!/bin/bash
# This script will generate passwords that will be used by the docker-compose file.
# Author: http://github.com/kiwimato

source functions.sh

ONLY_SUBDOMAINS=false
SUBDOMAINS=www,
TZ=Europe/Amsterdam

POSITIONAL=()
while [[ $# -gt 0 ]]
do
  key="$1"
  case ${key} in
      -s|--subdomains)
      SUBDOMAINS="$2,"
      shift # past argument
      shift # past value
      ;;
      -e|--email)
      EMAIL="$2"
      shift # past argument
      shift # past value
      ;;
      -t|--timezone)
      TZ="$2"
      shift # past argument
      shift # past value
      ;;
      -o|--only-subdomains)
      ONLY_SUBDOMAINS=true
      shift # past argument
      ;;
      --ignore-entropy)
      IGNORE_ENTROPY=true
      shift # past argument
      ;;
      -h|--help)
      show_help
      shift
      ;;
      *)    # url
      POSITIONAL+=("$1") # save it in an array for later
      shift # past argument
      ;;
  esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters

export URL="$1"

if [[ -z $1 ]] || [[ -z $EMAIL ]]; then
 echo -e "ERROR: Email or domain not provided. Both are mandatory\n"
 show_help
fi

ENTROPY="$(cat /proc/sys/kernel/random/entropy_avail)"
if [[ "${ENTROPY}" -lt 700 ]]; then
  echo "[WARNING]: Your system entropy is lower than 700: $ENTROPY. Running this script will result in generating insecure passwords"
  echo "[-] Please install tools like haveged, rngtools or generate I/O, like large find operations"
  echo "[-] To ignore it, you can use --ignore-entropy"
  [[ $IGNORE_ENTROPY ]] || exit -1
else
  echo "[+] Your entropy looks good: $ENTROPY"
fi

if [[ -f "data/env.sh" ]] || [[ -d "data" ]]; then
  echo -e "\nERROR: Either data/env.sh or data/ folder exists."
  echo -e "\t If you want to start from scratch just remove the data/env.sh and data/ folder. WARNING: You will lose DB credentials and any data already configured"
  echo -e "\t Otherwise, use ./start.sh"
  exit -1
fi

mkdir data
# Generate MySQL credentials
cat > data/env.sh<<EOF
export ADMIN_AUTH_USER="$(rpass 20)"
export ADMIN_AUTH_PASSWORD="$(rpass 42)"
export MYSQL_DATABASE="$(echo ${URL}_$(rpass 5) | tr '.' '_')"
export MYSQL_USER="$(rpass 20)"
export MYSQL_PASSWORD="$(rpass 42)"
export MYSQL_ROOT_PASSWORD="$(rpass 42)"
export SUBDOMAINS=${SUBDOMAINS}
export URL=${URL}
export EMAIL=${EMAIL}
export TZ=${TZ}
export ONLY_SUBDOMAINS=${ONLY_SUBDOMAINS}
EOF

echo "[+] Starting docker containers"
source data/env.sh
docker-compose up -d

# Wait a bit so folders are created under data/config
sleep 3

echo "[+] Downloading and installing WordPress"
cd data/config/www
wget https://wordpress.org/latest.tar.gz
tar xzf latest.tar.gz
mv wordpress/* .
chown 1000:1000 ./ -R
rm -rf latest.tar.gz wordpress

echo "[+] Created data/env.sh which containers all the credentials that will be used by Wordpress"
echo "[+] Access the following link to finish setting up WordPress https://${URL}"
echo "[*] You will need the following credentials:"
grep MYSQL_ data/env.sh | grep -v ROOT_
echo "[*] For Database Host type in: db"