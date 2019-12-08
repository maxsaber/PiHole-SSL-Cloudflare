# Automated Let's Encrypt certificates for Pi-Hole on Raspbian with Cloudflare
Use Cloudflare and Let's Encrypt to add a certificate to the Pi-Hole web interface and make the automatic renewal process work. 

Requires Certbot and the Cloudflare plugin.
```
sudo apt-get install python3-certbot-dns-cloudflare
```

### USAGE: 
```
./<script> <email address> <domain name> <path to Cloudflare auth file>
```
This script only needs to be run once, you can delete it after that. 

### References - 
  * https://discourse.pi-hole.net/t/enabling-https-for-your-pi-hole-web-interface/5771
  * https://tech.borpin.co.uk/2019/03/22/letsencrypt-ssl-certificates-by-dns-challenge-with-lighttpd/

Tested with Raspbian GNU/Linux 10 (buster) and Pi-Hole v4.3.2.