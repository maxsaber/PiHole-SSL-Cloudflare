#!/bin/bash

# Script to use Cloudflare and Let's Encrypt to add a certificate 
# to Pi-Hole and make the automatic renewal process work. 

# Requires Certbot and the Cloudflare plugin. 
# See 
# USAGE: ./<script> <domain name> <path to Cloudflare auth file>

# References - 
# https://discourse.pi-hole.net/t/enabling-https-for-your-pi-hole-web-interface/5771
# https://tech.borpin.co.uk/2019/03/22/letsencrypt-ssl-certificates-by-dns-challenge-with-lighttpd/

# Tested with Raspbian GNU/Linux 10 (buster) and Pi-Hole v4.3.2.

set -o errexit
set -o pipefail
DEBUG=${DEBUG:-"false"}
[[ "${DEBUG}" == "true" ]] && set -o xtrace functrace

EMAIL="$1"
MY_DOMAIN="$2"
CLOUDFLARE_AUTH="$3"

get_cert(){
	sudo certbot certonly \
		--non-interactive \
		--agree-tos \
		--email "$EMAIL" \
		--cert-name "$MY_DOMAIN" \
		--dns-cloudflare \
		--dns-cloudflare-credentials "$CLOUDFLARE_AUTH" \
		--dns-cloudflare-propagation-seconds 60 \
		-d "$MY_DOMAIN"

	printf "%s\n" "Got certificate for $MY_DOMAIN."
}

combine_keys(){
	local _private_key
	local _cert
	local _combined
	local _dirname

	_private_key="/etc/letsencrypt/live/$MY_DOMAIN/privkey.pem"
	_cert="/etc/letsencrypt/live/$MY_DOMAIN/cert.pem"
	_combined="/etc/letsencrypt/live/$MY_DOMAIN/combined.pem"
	_dirname="$(dirname "$_private_key")"
	# lighttpd requires that these files created by certbot be combined. 
	# See https://github.com/certbot/certbot/issues/94
	if [[ -f "$_private_key" ]] && [[ -f "$_cert" ]]; then
		sudo cat "$_private_key" "$_cert" | sudo tee "$_combined" > /dev/null
	else
		printf "%s\n" "Can't find the expected files at $_dirname."
		exit 1
	fi

	sudo chown www-data -R /etc/letsencrypt/live
	printf "%s\n" "Let's Encrypt keys combined."
}

setup_lighttpd(){
	# Create the required lighttpd file. This file won't be 
	# overwritten during pi-hole updates. 
	sudo tee "/etc/lighttpd/external.conf" > /dev/null << EOF
\$HTTP["host"] == "$MY_DOMAIN" {
  # Ensure the Pi-hole Block Page knows that this is not a blocked domain
  setenv.add-environment = ("fqdn" => "true")

  # Enable the SSL engine with a LE cert, only for this specific host
  \$SERVER["socket"] == ":443" {
    ssl.engine = "enable"
    ssl.pemfile = "/etc/letsencrypt/live/$MY_DOMAIN/combined.pem"
    ssl.ca-file =  "/etc/letsencrypt/live/$MY_DOMAIN/fullchain.pem"
    ssl.honor-cipher-order = "enable"
    ssl.cipher-list = "EECDH+AESGCM:EDH+AESGCM:AES256+EECDH:AES256+EDH"
    ssl.use-sslv2 = "disable"
    ssl.use-sslv3 = "disable"       
  }

  # Redirect HTTP to HTTPS
  \$HTTP["scheme"] == "http" {
    \$HTTP["host"] =~ ".*" {
      url.redirect = (".*" => "https://%0\$0")
    }
  }
}
EOF
	printf "%s\n" "/etc/lighttpd/external.conf written"
}

setup_post_renewal_hook(){
	# Certbot will automatically renew the cert, we need to combine 
	# it (as in combine_key() above) everytime that happens. 
	# Here we created a renewal hook that Certbot will run everytime the 
	# cert is succesfully renewed.
	# See https://certbot.eff.org/docs/using.html#pre-and-post-validation-hooks
	local _hook_path
	_hook_path="/etc/letsencrypt/renewal-hooks/deploy/combine.sh"
	
	sudo tee "$_hook_path" > /dev/null << 'EOF'
#!/bin/bash

for domain in $RENEWED_DOMAINS
do
	# Combine the certificate and private key file
	sudo cat "$_private_key" "$_cert" | sudo tee "$_combined"
    sudo cat /etc/letsencrypt/live/$domain/privkey.pem \
    /etc/letsencrypt/live/$domain/cert.pem > \
    /etc/letsencrypt/live/$MY_DOMAIN/combined.pem
done
EOF
	sudo chmod +x "$_hook_path"
	printf "%s\n" "Post-renewal hook set."
}

error(){
	printf "%s\n" "ERROR:"
	printf "%s\n" "Email, domain name and path to Cloudflare auth are required."
	printf "%s\n" "Example: $0 mymail@domain.com pi-hole.foo.net 
				   ~/.secrets/certbot/cloudflare.ini"
	exit 1
}

main(){

	if [[ -z "$MY_DOMAIN" ]] || [[ -z "$EMAIL" ]] || \
		[[ ! -f "$CLOUDFLARE_AUTH" ]]; then
		error
	fi

	get_cert
	combine_keys
	setup_lighttpd
	setup_post_renewal_hook
	systemctl restart lighttpd.service
}

main
printf "%s\n" "You may want to add a record to /etc/hosts for the $MY_DOMAIN name."
printf "%s\n" "Done."
exit 0