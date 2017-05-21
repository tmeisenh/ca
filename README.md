ca
==

Makefile that can create a root certificate authority, an intermediate (signing) authority and add clients.
Requires openssl and GNUMake

Create a root and intermediate ca
```bash
make ca intermediate
```
Add the "travis" client
```bash
make addclient client=travis
```

This [article](https://jamielinux.com/docs/openssl-certificate-authority/index.html) helped a lot and provided the openssl.cnf file.
