# shex2

shell extract and execute (`shex2`) extracts a compressed directory of scripts and then executes the desired scripts in that directory.

## Usage

### Command Line

```` 
./shex2.sh
		-a	absolute execute scripts - execute scripts at the provided absolute paths
		-b	basic auth - credentials to be passed to cURL
		-c	cleanup - delete extracted scripts upon completion
		-d	directory name - default: basename of extract file (no ext).
		-e	extract file - local or remote file path to compressed scripts directory
		-f	force - delete local scripts directory if it already exists
		-H	header - will be passed to cURL when downloading remote file
		-l	local path - used in conjunction with (-a). cd to this directory before executing absolute scripts
		-p	directory path - local path in which to extract scripts
		-r	remote pull - if (-e) is set to a remote resource, this flag must be set to pull from remote
		-x	execute scripts - these scripts will be executed in the extracted directory
````

#### Example

With a `compressed-scripts.tar.gz` file which decompresses to a single `scripts` directory which contains two scripts `test.sh` and `another.sh`:

````
compressed-scripts.tar.gz
- scripts
	test.sh
	another.sh
````

The following command will extract the `scripts` directory into `/some/other/path`, execute both scripts, and then delete the `scripts` directory once complete:

```` bash

./shex2.sh -e compressed-scripts.tar.gz \
	   -d scripts \
	   -p /some/other/path \
	   -x test.sh \
	   -x another.sh \
	   -c
````

##### Remote Pull

`shex2` will detect if your file is local or remote, and if the `-r` flag is set, will download the remote resource. This also works with `git` repositories:

```` bash
./shex2.sh -e git@github.com:user/test-scripts.git \
	   -d scripts \
	   -p /some/other/path \
	   -x test.sh \
	   -r

````

### Scripted

`shex2` can be imported into existing scripts and all the functionality can be scripted. Reference the CLI usage above for more detailed descriptions of the variable usage. 

```` bash
source shex2.sh

shex2 -e compressed-scripts.tar.gz \
	   -d scripts \
	   -p /some/other/path \
	   -x test.sh \
	   -x another.sh \
	   -c
````

## Security Note

**THIS WILL EXECUTE THE CONTENTS OF THE SCRIPTS PASSED TO IT. MAKE SURE YOU WANT TO DO THIS.**

**WHEN USING THE REMOTE OPTION, YOU WILL BE EXECUTING SCRIPTS PULLED IN OVER THE WIRE.**

The entire functionality of this script is to extract and execute scripts.

The remote option is not intended to be used with random scripts on the web - it is meant to pull from internal artifact / object servers which you control. `shex2` will cowardly fail to pull from remote unless the `-r` flag is set.
