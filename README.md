# Independent WordPress
This is a small project which helps with running WordPress within Docker.
For certificates it makes use of LetsEncrypt and fail2ban for increased security.

## First run:
```bash
./init.sh -e my@email.com myawesome.org 
```

## LetsEncrypt container options
Container images are configured using parameters passed at runtime (such as those above). These parameters are separated by a colon and indicate `<external>:<internal>` respectively. For example, `-p 8080:80` would expose port `80` from inside the container to be accessible from the host's IP on port `8080` outside the container.

| Parameter | Function |
| :----: | --- |
| `-p 443` | Https port |
| `-p 80` | Http port (required for http validation and http -> https redirect) |
| `-e PUID=1000` | for UserID - see below for explanation |
| `-e PGID=1000` | for GroupID - see below for explanation |
| `-e TZ=Europe/London` | Specify a timezone to use EG Europe/London. |
| `-e URL=yourdomain.url` | Top url you have control over (`customdomain.com` if you own it, or `customsubdomain.ddnsprovider.com` if dynamic dns). |
| `-e SUBDOMAINS=www,` | Subdomains you'd like the cert to cover (comma separated, no spaces) ie. `www,ftp,cloud`. For a wildcard cert, set this _exactly_ to `wildcard` (wildcard cert is available via `dns` and `duckdns` validation only) |
| `-e VALIDATION=http` | Letsencrypt validation method to use, options are `http`, `dns` or `duckdns` (`dns` method also requires `DNSPLUGIN` variable set) (`duckdns` method requires `DUCKDNSTOKEN` variable set, and the `SUBDOMAINS` variable must be either empty or set to `wildcard`). |
| `-e DNSPLUGIN=cloudflare` | Required if `VALIDATION` is set to `dns`. Options are `aliyun`, `cloudflare`, `cloudxns`, `cpanel`, `digitalocean`, `dnsimple`, `dnsmadeeasy`, `domeneshop`, `gandi`, `google`, `inwx`, `linode`, `luadns`, `nsone`, `ovh`, `rfc2136`, `route53` and `transip`. Also need to enter the credentials into the corresponding ini (or json for some plugins) file under `/config/dns-conf`. |
| `-e PROPAGATION=` | Optionally override (in seconds) the default propagation time for the dns plugins. |
| `-e DUCKDNSTOKEN=` | Required if `VALIDATION` is set to `duckdns`. Retrieve your token from https://www.duckdns.org |
| `-e EMAIL=` | Optional e-mail address used for cert expiration notifications. |
| `-e ONLY_SUBDOMAINS=false` | If you wish to get certs only for certain subdomains, but not the main domain (main domain may be hosted on another machine and cannot be validated), set this to `true` |
| `-e EXTRA_DOMAINS=` | Additional fully qualified domain names (comma separated, no spaces) ie. `extradomain.com,subdomain.anotherdomain.org,*.anotherdomain.org` |
| `-e STAGING=false` | Set to `true` to retrieve certs in staging mode. Rate limits will be much higher, but the resulting cert will not pass the browser's security test. Only to be used for testing purposes. |
| `-v /config` | All the config files including the webroot reside here. |


## Stack:
 * SSL certificates provided by LetsEncrypt
 * Fail2ban - configured to ban bots and bruteforcers
 * NginX
 * PHP 
 * MySQL
 
All the credentials needed will be then saved in `data/env.sh`.

TODO:
  * Use wp-cli to automatically configure wordpress.
  *  Note: By default `/wp-login.php` will be protected by another layer of security. 
     You can get the credentials for it in `data/env.sh` and have the prefix `WWW_BASIC`.
     This is mostly for Fail2ban, which can use any failed login attempts to block attackers.
  * Ownership of nginx config files, should be more secure 

This is based on hard work from the Linuxserver.io, especially https://github.com/linuxserver/docker-letsencrypt/blob/master/README.md