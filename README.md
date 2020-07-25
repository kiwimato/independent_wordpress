# Independent WordPress
This is just a wrapper over some other people's hard work which make it easier to launch WordPress using Docker.

## First run:
```bash
./init.sh -e my@email.com myawesome.org 
```

## Stack:
 * Certificates provided by [docker-letsencrypt](https://github.com/linuxserver/docker-letsencrypt/blob/master/README.md)
 * Fail2ban - configured to ban bots and bruteforcers
 * Nginx
 * PHP 
 * Mysql
 
All the credentials needed will be then saved in `data/env.sh`.

TODO:
  *  Note: By default `/wp-login.php` will be protected by another layer of security. 
     You can get the credentials for it in `data/env.sh` and have the prefix `WWW_BASIC`.
     This is mostly for Fail2ban, which can use any failed login attempts to block attackers.
  * Ownership of nginx config files, should be more secure 