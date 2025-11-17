# for /home/build/src/onie/encryption/onie-encrypt.sh generate-all-keys

EFI_TOOLS_VERSION="1.9.2"
EFI_TOOLS_URL="https://git.kernel.org/pub/scm/linux/kernel/git/jejb/efitools.git/snapshot/efitools-${EFI_TOOLS_VERSION}.tar.gz"
echo "Downloading efi tools."
wget $EFI_TOOLS_URL || exit 1
tar -xvf efitools-${EFI_TOOLS_VERSION}.tar.gz || exit 1
cd efitools-${EFI_TOOLS_VERSION}
echo "Building efi tools"
make || exit 1
echo "Installing *efi in /usr/local/bin"
make install || exit 1

# cmd above should result in something like this
#
# /home/build/src/onie/encryption/machines/kvm_x86_64/keys
# |-- HW
# |   |-- efi-keys
# |   |   |-- HW-database-key-cert.der
# |   |   |-- HW-database-key-cert.pem
# |   |   |-- HW-database-key-cert.req
# |   |   |-- HW-database-key-public-key.pem
# |   |   |-- HW-database-key-secret-key.pem
# |   |   |-- HW-key-exchange-key-cert.der
# |   |   |-- HW-key-exchange-key-cert.pem
# |   |   |-- HW-key-exchange-key-cert.req
# |   |   |-- HW-key-exchange-key-public-key.pem
# |   |   |-- HW-key-exchange-key-secret-key.pem
# |   |   |-- HW-platform-key-cert.der
# |   |   |-- HW-platform-key-cert.pem
# |   |   |-- HW-platform-key-cert.req
# |   |   |-- HW-platform-key-public-key.pem
# |   |   `-- HW-platform-key-secret-key.pem
# |   |-- gpg-keys
# |   |   |-- HW-public.asc
# |   |   |-- HW-pubring.kbx
# |   |   |-- HW-secret.asc
# |   |   |-- S.gpg-agent
# |   |   |-- S.gpg-agent.browser
# |   |   |-- S.gpg-agent.extra
# |   |   |-- S.gpg-agent.ssh
# |   |   |-- private-keys-v1.d
# |   |   |   `-- 780FD42F67347015EA7807A22057749D4E74F0FE.key
# |   |   |-- pubring.kbx
# |   |   `-- trustdb.gpg
# |   `-- pkcs12-keys
# |-- ONIE
# |   |-- efi-keys
# |   |   |-- ONIE-shim-key-cert.der
# |   |   |-- ONIE-shim-key-cert.pem
# |   |   |-- ONIE-shim-key-cert.req
# |   |   |-- ONIE-shim-key-public-key.pem
# |   |   `-- ONIE-shim-key-secret-key.pem
# |   |-- gpg-keys
# |   |   |-- ONIE-public.asc
# |   |   |-- ONIE-pubring.kbx
# |   |   |-- ONIE-secret.asc
# |   |   |-- S.gpg-agent
# |   |   |-- S.gpg-agent.browser
# |   |   |-- S.gpg-agent.extra
# |   |   |-- S.gpg-agent.ssh
# |   |   |-- private-keys-v1.d
# |   |   |   `-- 1B68715956C8067613D0C32420A64494CDA42573.key
# |   |   |-- pubring.kbx
# |   |   `-- trustdb.gpg
# |   `-- pkcs12-keys
# |       |-- ONIE-shim-key-private-key.key
# |       |-- ONIE-shim-key.p12
# |       |-- cert9.db
# |       |-- key4.db
# |       `-- pkcs11.txt
# |-- SW
# |   |-- efi-keys
# |   |   |-- SW-database-key-cert.der
# |   |   |-- SW-database-key-cert.pem
# |   |   |-- SW-database-key-cert.req
# |   |   |-- SW-database-key-public-key.pem
# |   |   |-- SW-database-key-secret-key.pem
# |   |   |-- SW-key-exchange-key-cert.der
# |   |   |-- SW-key-exchange-key-cert.pem
# |   |   |-- SW-key-exchange-key-cert.req
# |   |   |-- SW-key-exchange-key-public-key.pem
# |   |   `-- SW-key-exchange-key-secret-key.pem
# |   |-- gpg-keys
# |   |   |-- S.gpg-agent
# |   |   |-- S.gpg-agent.browser
# |   |   |-- S.gpg-agent.extra
# |   |   |-- S.gpg-agent.ssh
# |   |   |-- SW-public.asc
# |   |   |-- SW-pubring.kbx
# |   |   |-- SW-secret.asc
# |   |   |-- private-keys-v1.d
# |   |   |   `-- D1E9E86842C2A5CFBA12C7359F6B1F43AD770C1F.key
# |   |   |-- pubring.kbx
# |   |   `-- trustdb.gpg
# |   `-- pkcs12-keys
# `-- efiVars
#     |-- db-all.auth
#     `-- kek-all.auth
# 
# 16 directories, 67 files