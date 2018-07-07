#!/bin/bash

function clear_variables () {
	EXTRACT_FILE=""
	EXTRACT_DIRECTORY_PATH=""
	DIRECTORY_NAME=""
	LOCAL_EX_PATH=""
	FORCE_EXECUTE=false
	CLEANUP=false
	ALLOW_REMOTE_PULL=false
	EXECUTE_SCRIPTS=()
	ABS_EX_SCRIPTS=()
	HEADERS=()
	IS_GIT=""
}

function display_usage () {
cat << EOF
	./shex2.sh
		-a	absolute execute scripts - execute scripts at the provided absolute paths
		-b	basic auth - set basic auth credentials to be passed to cURL
		-c	cleanup - delete extracted scripts upon completion
		-d	directory name - default: basename of extract file (no ext).
		-e	extract file - local or remote file path to compressed scripts directory
		-f	force - delete local scripts directory if it already exists
		-H	header - will be passed to cURL when downloading remote file
		-l	local path - used in conjunction with (-a). cd to this directory before executing absolute scripts
		-p	directory path - local path in which to extract scripts
		-r	remote pull - if (-e) is set to a remote resource, this flag must be set to pull from remote
		-x	execute scripts - these scripts will be executed in the extracted directory
EOF
exit
}

function mime_type () {
	MIME_TYPE=$(file --mime-type $1)
	MIME_TYPE=$(echo $MIME_TYPE | awk '{print $2}')
	echo $MIME_TYPE
}

function directory_name () {
	DIRECTORY_NAME=$(basename $1 | awk -F'.' '{print $1}')
	echo $DIRECTORY_NAME
}

function check_directory_exits () {
	CHECK_DIR=""
	if [ ! -z "$2" ]; then
		CHECK_DIR="$2/$1"
	else
		CHECK_DIR="$1"
	fi
	if [ -d "$CHECK_DIR" ]; then
		if [ "$FORCE_EXECUTE" == false ]; then
			echo "Directory Already Exists. Use -f to remove."
			exit 1
		else
			rm -rf $CHECK_DIR
		fi	
	fi
}

function execute_scripts () {
	EXPATH=$EXTRACT_DIRECTORY_PATH/$DIRECTORY_NAME
	if [ ! -z "$LOCAL_EX_PATH" ]; then
		cd "$LOCAL_EX_PATH"
	fi
	for s in "${ABS_EX_SCRIPTS[@]}"; do
		$s
	done
	for s in "${EXECUTE_SCRIPTS[@]}"; do
		cd $EXPATH
		./$s
	done
}

function cleanup () {
	rm -rf $EXTRACT_DIRECTORY_PATH/$DIRECTORY_NAME
}

function curl_headers () {
	HEADER_STRING=""
	if [ ${#HEADERS[@]} -gt 0 ]; then
		for h in ${HEADERS[@]}; do
			HEADER_STRING+="-H '$h' "
		done
	fi
	echo $HEADER_STRING
}

function basic_auth () {
	if [ ! -z "$BASIC_AUTH" ]; then
		echo "-u $BASIC_AUTH "
	fi
}

function download_remote () {
	NEEDS_DOWNLOAD=false
	IS_HTTP=$(echo $1 | head -c 6 | grep -e '^ht.*[p|s]:' | xargs)
	IS_GIT=$(echo $1 | tail -c 6 | grep -e '.*\.git$' | xargs)
	if [ ${#IS_HTTP} -gt 0 ] || [ ${#IS_GIT} -gt 0 ]; then
		NEEDS_DOWNLOAD=true
	fi
	if [ "$ALLOW_REMOTE_PULL" == false ] && [ "$NEEDS_DOWNLOAD" == true ]; then
		echo "Use -r flag to enable remote pull."
		exit 1
	fi
	if [ ! -z "$IS_GIT" ]; then
		git clone $(echo $1 | xargs) $EXTRACT_DIRECTORY_PATH/$DIRECTORY_NAME
	elif [ ! -z "$IS_HTTP" ]; then
		CMD=("curl")
		CMD+=("-o $(basename $1)")
		CMD+=(`curl_headers`)
		CMD+=(`basic_auth`)
		CMD+=("$1")
		`${CMD[@]}`
	fi
	if [ $? != 0 ]; then
		echo "Download failed."
		exit 1
	fi
}

function extract_file () {
	download_remote $1
	if [ ! -z "$IS_GIT" ]; then
		if [ ! -d "$EXTRACT_DIRECTORY_PATH/$DIRECTORY_NAME" ]; then
			echo $EXTRACT_DIRECTORY_PATH/$DIRECTORY_NAME directory does not exist
			exit 1
		fi
		return 0	
	fi
	LOCAL_FILENAME=`basename $1`
	if [ ! -f "$LOCAL_FILENAME" ]; then
		echo $LOCAL_FILENAME does not exist.
		exit 1
	fi
	echo Extracting File $LOCAL_FILENAME into $2
	if [ ! -d "$2" ]; then
		mkdir -p $2
	fi
	MIME_TYPE=$(mime_type $LOCAL_FILENAME)
	if [[ "$MIME_TYPE" =~ .*"x-tar" ]]; then
		tar -xvf $LOCAL_FILENAME -C $2
	elif [[ "$MIME_TYPE" =~ .*"x-gzip" ]]; then
		tar -zxvf $LOCAL_FILENAME -C $2
	elif [[ "$MIME_TYPE" =~ .*"zip" ]]; then
		unzip $LOCAL_FILENAME -d $2
	fi
	if [ $? != 0 ]; then
		echo Error extracting file.
		exit 1
	fi
	echo $LOCAL_FILENAME extracted into $2
}

CLI_OPTIONS=":a:b:cd:e:fH:l:p:rx:"

function shex2 () {
	while getopts "$CLI_OPTIONS" o; do
		case $o in
			a)
				ABS_EX_SCRIPTS+=("$OPTARG")
				;;
			b)
				BASIC_AUTH=$OPTARG
				;;
			c)
				CLEANUP=true
				;;
			d)
				DIRECTORY_NAME=$OPTARG
				;;
			e)
				EXTRACT_FILE=$OPTARG
				;;
			f)
				FORCE_EXECUTE=true
				;;
			H)
				HEADERS+=("$OPTARG")
				;;
			l)
				LOCAL_EX_PATH=$OPTARG
				;;
			p)
				EXTRACT_DIRECTORY_PATH=$OPTARG
				;;
			r)
				ALLOW_REMOTE_PULL=true
				;;
			x)
				EXECUTE_SCRIPTS+=("$OPTARG")
				;;
			\?)
				display_usage
				;;
		esac
	done

	if [ -z "$EXTRACT_DIRECTORY_PATH" ]; then
		EXTRACT_DIRECTORY_PATH=`pwd`
	fi
	if [ -z "$DIRECTORY_NAME" ]; then
		DIRECTORY_NAME=$(directory_name $EXTRACT_FILE)
	fi
	check_directory_exits $DIRECTORY_NAME $EXTRACT_DIRECTORY_PATH
	extract_file $EXTRACT_FILE $EXTRACT_DIRECTORY_PATH
	execute_scripts
	if [ "$CLEANUP" == true ]; then
		cleanup
	fi
	clear_variables
}

clear_variables
while getopts "$CLI_OPTIONS" o; do
	case $o in
			a)
				ABS_EX_SCRIPTS+=("$OPTARG")
				;;
			b)
				BASIC_AUTH=$OPTARG
				;;
			c)
				CLEANUP=true
				;;
			d)
				DIRECTORY_NAME=$OPTARG
				;;
			e)
				EXTRACT_FILE=$OPTARG
				;;
			f)
				FORCE_EXECUTE=true
				;;
			H)
				HEADERS+=("$OPTARG")
				;;
			l)
				LOCAL_EX_PATH=$OPTARG
				;;
			p)
				EXTRACT_DIRECTORY_PATH=$OPTARG
				;;
			r)
				ALLOW_REMOTE_PULL=true
				;;
			x)
				EXECUTE_SCRIPTS+=("$OPTARG")
				;;
			\?)
				display_usage
				;;
	esac
done

if [ ! -z "$EXTRACT_FILE" ]; then
	shex2
fi
