## Automated Let's Encrypt certificates for Pi-Hole on Raspbian with Cloudflare
Use Cloudflare and Let's Encrypt to add a certificate to the Pi-Hole web interface and make the automatic renewal process work. 

Requires Certbot and the Cloudflare plugin.
```
sudo apt-get install certbot python3-certbot-dns-cloudflare
```

### USAGE: 
```
$ wget https://raw.githubusercontent.com/maxsaber/PiHole-SSL-Cloudflare/master/Pi-Hole_Cloudflare_TLS.sh
$ chmod +x Pi-Hole_Cloudflare_TLS.sh
$ sudo ./Pi-Hole_Cloudflare_TLS.sh <email address> <domain name> <path to Cloudflare auth file>
```
This script only needs to be run once, you can delete it after that. 

### References - 
  * Original: https://github.com/Gestas/Pi-Hole-TLS-with-Cloudflare
  * https://discourse.pi-hole.net/t/enabling-https-for-your-pi-hole-web-interface/5771
  * https://tech.borpin.co.uk/2019/03/22/letsencrypt-ssl-certificates-by-dns-challenge-with-lighttpd/

Tested with Raspbian GNU/Linux 10 (buster) and Pi-Hole v5.1.3
