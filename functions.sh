function show_help(){
      echo "Usage: $0 [options] <domain>"
      echo -e "\n\tOptional arguments:"
      echo -e "\t-s|--subdomains <subdomains> \t The subdomains for the domain. If multiple, separate by comma. Default: www"
      echo -e "\t-t|--timezone \t\t\t Specific timezone. Example: Europe/Amsterdam"
      echo -e "\t-o|--only-subdomains \t\t If you wish to get certs only for certain subdomains, but not the main domain (main domain may be hosted on another machine and cannot be validated)"
      echo -e "\n\tMandatory arguments:"
      echo -e "\t<domain> \t The domain for the wordpress blog."
      echo -e "\t-e|--email \t\t\t Email for Letsencrypt for certificate notices, renewal etc."
      echo -e "\n\tExample:"
      echo -e "\t$0 -e my@email.com domain"
      echo -e "\t$0 -e my@email.com -s www myawesome.org"
      exit 0
}
function rpass() {
  LENGTH=$1 # Password length
  cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w ${1:-$LENGTH} | head -n 1 | tr -d '\n'
}