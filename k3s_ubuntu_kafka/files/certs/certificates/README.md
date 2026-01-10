# Description #
This doc describe the approch to create our TLS certificates

# commands #
in certificates folder run:

## CA Private key ##

openssl genrsa -des3 -out rootCA.key 2048  (passphrase : sharks)

## CA Certificate ##
openssl req -x509 -new -nodes -key rootCA.key -sha256 -days 1825 -out CA.pem

check cert
openssl x509 -in cacerts.pem -text -noout

## Create server certificates ##

openssl genrsa -out sharks4it.key 2048
openssl req -new -key sharks4it.key -out sharks4it.dk.csr
openssl x509 -req -in sharks4it.dk.csr -CA CA.pem -CAkey rootCA.key -CAcreateserial -out sharks4it.crt -days 825 -sha256 -extfile sharks4it.ext

NOTE:
To open certs & keyfiles in Keystore Explorer choose PKCS#8 format
