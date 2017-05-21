ca
==

Makefile that can create a root certificate authority, an intermediate (signing) authority and add clients.
Requires openssl and GNUMake

Create a root and intermediate ca
```bash
make ca intermediate
```
Create the chain of trust that has all the CA certs
```bash
make chain
```
Validate the chain of trust
```bash
make validate
```

Add the "travis" client
```bash
make addclient client=travis
```

This [article](https://jamielinux.com/docs/openssl-certificate-authority/index.html) helped a lot and provided the openssl.cnf file.
