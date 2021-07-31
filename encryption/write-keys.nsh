# Script to set KEK and DB UEFI variables from UEFI shell
#  Copyright (C) 2021 Alex Doyle <adoyle@nvidia.com>

# To use - copy it to a partition like /boot/efi or have it
# on a USB filesystem.
#  Note that it expects its filesystem to have been created
#   by running ONIE's "make signing-key-install" command
#
# When in the UEFI shell
#  fsX:   <- set filesystem 
#  ls     <- verify contents of filesystem
#  write-keys.nsh  <- run this script

# UEFI Errors decoded:
# code, mnemonic, description:
# 0 SHELL_SUCCESS              - The operation completed successfully
# 1 SHELL_LOAD_ERROR           - The image failed to load.
# 2 SHELL_INVALID_PARAMETER    - There was an error in the command-line options.
# 3 SHELL_UNSUPPORTED          - The operation is not supported.
# 4 SHELL_BAD_BUFFER_SIZE      - The buffer was not the proper size for the request.
# 5 SHELL_BUFFER_TOO_SMALL     - The buffer is not large enough to hold the requested data.  The required buffer size is returned in the appropriate parameter whenthis error occurs.
# 6 SHELL_NOT_READY            - There is no data pending upon return.
# 7 SHELL_DEVICE_ERROR         - The physical device reported an error while attempting the operation.
# 8 SHELL_WRITE_PROTECTED      - The device cannot be written to.
# 9 SHELL_OUT_OF_RESOURCES     - A resource has run out.
#10 SHELL_VOLUME_CORRUPTED     - An inconstancy was detected on the file system causing the operating to fail.
#11 SHELL_VOLUME_FULL          - There is no more space on the file system.
#12 SHELL_NO_MEDIA             - The device does not contain any medium to perform the operation.
#13 SHELL_MEDIA_CHANGED        - The medium in the device has changed since the last access.
#14 SHELL_NOT_FOUND            - The item was not found.
#15 SHELL_ACCESS_DENIED        - Access was denied.
#18 SHELL_TIMEOUT              - The timeout time expired.
#19 SHELL_NOT_STARTED          - The specified operation could not be started.
#20 SHELL_ALREADY_STARTED      - The specified operation had already started.
#21 SHELL_ABORTED              - The operation was aborted by the user
#25 SHELL_INCOMPATIBLE_VERSION - The function encountered an internal version that was incompatible with a version requested by the caller.
#26 SHELL_SECURITY_VIOLATION   - The function was not performed due to a security violation.
#27 SHELL_NOT_EQUAL            - The function was performed and resulted in an unequal comparison

@echo -off
# Wipe the screen. cls [0-7] will set a color
cls
echo "Key install script for UEFI"
echo " ---------------------------"
echo " Checking value of KEK. For a first time install it should NOT be set."
echo " Expect the following message: "
echo "    dmpstore: No matching variables found... Guid <foo> Name kek"
# Echo a space for a new line. Double quotes errors as null string
echo " "
dmpstore kek

echo " Adding db-all.auth to UEFI db database."
echo "  This adds hardware and software supplier public DB certificates."
echo " "
# The path set up by the emulation build on the 'usb disk'
.\efi-binaries\UpdateVars.efi db ..\efiVars\db-all.auth
if %lasterror% ne 0x0 then
  echo "Error [ %lasterror% ] on db set"
  goto EXITSCRIPT
endif

echo " "
echo " Adding kek-all.auth to the KEK database"
echo "  This adds hardware and software supplier public KEK certificates."

.\efi-binaries\UpdateVars.efi KEK ..\efiVars\kek-all.auth
if  %lasterror% ne 0x0  then
  echo "Error [ %lasterror% ] on KEK set"
  goto EXITSCRIPT
endif

# Success message is skipped over if there is an error.
echo " "
echo "Success! Updated db and KEK."
echo " Type: 'dmpstore db' to see the db value."
echo " Type: 'dmpstore kek' to see the kek value."
echo " Type: 'edit ReadmeUEFI' for further UEFI key set instructions."

:EXITSCRIPT

