#!/bin/bash
#------------------------------------------------------------------------------
# This script was inspired from contents of TheUrbanPenguin:
# Masterclasss in openSSL: https://www.youtube.com/watch?v=d8OpUcHzTeg&t=2010s
# https://www.theurbanpenguin.com/
#------------------------------------------------------------------------------

rootDir=ca
rootCA=root-ca #Root certification authority
subCA=sub-ca   #Intermediary certification authority
server=server  #Server certificates

#Create basic folder structure
mkdir -p $rootDir/{$rootCA,$subCA,$server}/{private,certs,newcerts,crl,csr}
#Apply security constraits in ./rootDir/.../private directories
chmod -v 700 $rootDir/{$rootCA,$subCA,$server}/private

# - Root CA certificate - 
echo "- Root CA Private key -"
touch $rootDir/$rootCA/index
openssl rand -hex 16 > $rootDir/$rootCA/serial
openssl genrsa -aes256 -out $rootDir/$rootCA/private/$rootCA.key 4096
cat root-ca.conf > $rootDir/$rootCA/$rootCA.conf
echo "- Root CA certificate -"
openssl req \
  -config $rootDir/$rootCA/$rootCA.conf     \
  -key $rootDir/$rootCA/private/$rootCA.key \
  -new -x509 \
  -out $rootDir/$rootCA/certs/$rootCA.crt   

# - Intermediate CA Certificate -
touch $rootDir/$subCA/index
openssl rand -hex 16 > $rootDir/$subCA/serial
cat sub-ca.conf > $rootDir/$subCA/$subCA.conf
echo "Intermediate CA private key"
openssl genrsa -aes256 -out $rootDir/$subCA/private/$subCA.key 4096

echo "Intermediate CA Certifiate Sign Request"
openssl req \
  -config $rootDir/$subCA/$subCA.conf     \
  -key $rootDir/$subCA/private/$subCA.key \
  -new -sha256 \
  -out $rootDir/$subCA/csr/$subCA.csr

echo "Intermediate CA Certificate"
openssl ca \
  -config $rootDir/$rootCA/$rootCA.conf \
  -extensions v3_intermediate_ca        \
  -days 3650 -notext                    \
  -in $rootDir/$subCA/csr/$subCA.csr    \
  -out $rootDir/$subCA/certs/$subCA.crt

# - Server Certificate -
touch $rootDir/$server/index
openssl rand -hex 16 > $rootDir/$server/serial

echo "Server Private Key"
openssl genrsa -out $rootDir/$server/private/$server.key 2048 

echo "Server Certificate Sign Request"
openssl req \
  -key $rootDir/$server/private/$server.key \
  -new -sha256 \
  -out $rootDir/$server/csr/$server.csr

echo "Server Certificate Signing"
openssl ca \
  -config $rootDir/$subCA/$subCA.conf \
  -extensions server_cert               \
  -days 365 -notext                     \
  -in $rootDir/$server/csr/$server.csr  \
  -out $rootDir/$server/certs/$server.crt

# - nginx -
cat $rootDir/$server/certs/$server.crt \
    $rootDir/$subCA/certs/$subCA.crt   \
    >  $rootDir/$server/certs/chained.crt
