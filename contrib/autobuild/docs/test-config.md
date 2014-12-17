# Test Definition Config File for OCE (ONIE Compliance Environment)

This file will go over the basic definition and various sections of the config
file that is used within OCE.

## Structure

The config file is a JSON object with the following attributes:
* ```name```
* ```available-services```
* ```names```
* ```tests```

## name
This is the name of the definition file.  This item is not used within OCE but
is intended to be used by the user to provide context for various OCE config files.

## available-services
This is a dictionary (associated arrary) consisting of the various services
needed by OCE (```dhcp```, ```tftp```, ```http```, etc...) and the corresponding implementation
by it's module name (located in ```modules```).

## names
This is a dictionary consisting of the various naming schemes that is supported
by ONIE.  The key in the dictionary, correlates to a given test name (more details below).
Each value is essentially a jinja template for easy substitution.

## tests
This is a dictionary consisting of all ONIE test cases per the ONIE specification.
Each key is the representative test case as described by the ONIE specification.
Each value is a test object.

### test
Each test object has the following attributes:
* ```name```
* ```required-services```
* ```action```

```name``` is the name of the test case as described by the ONIE test report.
```required-services``` is a list of services required to perform this test using
the keys found in ```available-services``` (i.e. ```dhcp```, ```tftp```, etc...).
This can be an empty list to indicate no services are required (like USB installation/update).
```action``` is one of the following values:
* ```power-cycle```
* ```warm-reboot```
* ```static-installer```
* ```installer```
* ```static-updater```
* ```updater```
* ```uninstaller```
* ```rescuer```

A value of ```static-*``` is to represent a value that is statically provided to ONIE via
the console vs ONIE's image discovery process.
