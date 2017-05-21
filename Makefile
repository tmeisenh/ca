# Author: Travis B. Meisenheimer
#
# Makefile to create a root ca, an intermediate (signing) ca, and issue client certs.
#
#	to read a cert:  openssl x509 -noout -text -in $1
#	to read a csr: openssl req -noout -text -in $1
#	to check a csr: openssl req -text -noout -verify -in $1

.PHONY = usage clean validate addclient

CURVE_NAME = secp384r1
DN_BASE = /C=US/ST=Missouri/L=Saint Peters/O=indexoutofbounds/OU=Engineering

default: usage

usage:
	@echo "---------- Certificate Authority Creation ----------------------------"
	@echo "Available tasks:"
	@echo "clean: removes all generated files"
	@echo "ca: creates the root key and certificate"
	@echo "intermediate: creates the intermediate (signing) ca"
	@echo "chain: bundles up the root and intermediate ca certs into one pem file"
	@echo "validate: validates that the intermediate and root certs are in a chain"
	@echo "addclient(param:client): generates keys and certs for a client"
	@echo "----------------------------------------------------------------------"

clean:
	@rm -rf ca intermediate chain clients

ca:
	@echo "Creating root ca"
	$(call setup_ca,ca)
	$(call generate_key,ca,ca)
	@openssl req -config openssl.cnf -new -x509 \
		-extensions v3_ca \
		-subj '$(DN_BASE)/CN=Root CA Authority' \
		-key ca/private/ca.key.pem \
		-out ca/certs/ca.cert.pem

intermediate: ca 
	@echo "Creating intermediate ca"
	$(call setup_ca,intermediate)
	$(call generate_key,intermediate,intermediate)
	$(call create_csr,intermediate,intermediate,Intermediate CA Authority)
	$(call sign_csr,intermediate,intermediate,root_ca,v3_intermediate_ca,3650)
	@mkdir clients

chain: intermediate
	@mkdir chain
	@cat intermediate/certs/intermediate.cert.pem ca/certs/ca.cert.pem > chain/ca-chain.cert.pem
	@chmod 444 chain/ca-chain.cert.pem

validate: 
	@echo "Validating intermediate chain of trust..."
	@openssl verify -CAfile ca/certs/ca.cert.pem \
		      intermediate/certs/intermediate.cert.pem

# expects parameter client 
addclient: 
	@echo "Creating certs for client: $(client)"
	@rm -rf clients/$(client)
	$(call setup_directory,clients/$(client))
	$(call generate_key,$(client),clients/$(client))
	$(call create_csr,$(client),clients/$(client),$(client))
	$(call sign_csr,$(client),clients/$(client),intermediate_ca,server_cert,365)

### Custom functions

# name/rootPath
define setup_directory
	@mkdir $(1) $(1)/certs $(1)/private $(1)/csr
	@chmod 700 $(1)/private
endef

# name/rootPath
define setup_ca
	$(call setup_directory,$(1))
	@mkdir $(1)/crl $(1)/newcerts
	@touch $(1)/index.txt
	@touch $(1)/index.txt.attr
	@echo 1000 > $(1)/serial
	@echo 1000 > $(1)/crlnumber
endef

# name, rootPath
define generate_key
	@openssl ecparam -genkey -name $(CURVE_NAME) -out $(2)/private/$(1).key.pem
	@chmod 400 $(2)/private/$(1).key.pem
endef

# name, rootPath, subject
define create_csr
	@openssl req -config openssl.cnf \
		-new -sha256 \
		-subj '$(DN_BASE)/CN=$(3)' \
		-key $(2)/private/$(1).key.pem \
		-out $(2)/csr/$(1).csr.pem	
endef

# name, rootPath, signing_ca, extensions, days
define sign_csr
	@openssl ca -config openssl.cnf -batch \
		-name $(3) \
		-extensions $(4)\
		-days $(5) -notext -md sha256 \
		-in $(2)/csr/$(1).csr.pem \
		-out $(2)/certs/$(1).cert.pem
endef
