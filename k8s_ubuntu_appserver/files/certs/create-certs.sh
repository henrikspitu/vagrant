#!/bin/bash




mkdir /home/vagrant/tls-certs

cat >>/home/vagrant/tls-certs/sharks4it.ext<<EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = *.sharks4it.dk
EOF

openssl genrsa -des3 -passout pass:sharks -out /home/vagrant/tls-certs/rootCA.key 2048

openssl req -x509 -new -nodes -key /home/vagrant/tls-certs/rootCA.key -sha256 -days 1825 -out /home/vagrant/tls-certs/CA.pem -passin pass:sharks -subj '/C=DK/ST=DK/L=Lejre/CN=sharks4it.dk'

openssl genrsa -out /home/vagrant/tls-certs/sharks4it.key 2048

openssl req -new -key /home/vagrant/tls-certs/sharks4it.key -out /home/vagrant/tls-certs/sharks4it.dk.csr -passin pass:sharks -subj '/C=DK/ST=DK/L=Lejre/CN=sharks4it.dk'

openssl x509 -req -in /home/vagrant/tls-certs/sharks4it.dk.csr -CA /home/vagrant/tls-certs/CA.pem -CAkey /home/vagrant/tls-certs/rootCA.key -CAcreateserial -out /home/vagrant/tls-certs/sharks4it.crt -days 825 -sha256 -extfile /home/vagrant/tls-certs/sharks4it.ext -passin pass:sharks