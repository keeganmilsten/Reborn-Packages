#!/usr/bin/env bash

# Path to the repository containing the database, signatures and packages
REPO_PATH="/home/$USER/Dropbox/Linux/RebornOS-Repo/"
TMP_PATH="/tmp/check_repo"
TMP_DB_PATH="${TMP_PATH}/db"
PACKAGE_REGEX=".*/(.*)-[^-]*-[^-]*-[^-]*\.pkg.*"

mkdir -p ${TMP_PATH}

# Collecting data
PACKAGES=($(find "${REPO_PATH}" -name "*.pkg.*" -not -name "*.sig" | sort))
SIGNATURES=($(find "${REPO_PATH}" -name "*.pkg.*" -name "*.sig" | sort))
DATABASE=($(find "${REPO_PATH}" -name "*.db.*" -not -name "*.sig" -not -name "*.old" | sort))
DATABASE_SIGNATURE=($(find "${REPO_PATH}" -name "*.db.*" -name "*.sig" -not -name "*.old" | sort))
FILES=($(find "${REPO_PATH}" -name "*.files.*" -not -name "*.sig" -not -name "*.old" | sort))
FILES_SIGNATURE=($(find "${REPO_PATH}" -name "*.files.*" -name "*.sig" -not -name "*.old" | sort))

# Statistics
echo "Packages: ${#PACKAGES[@]}"
echo "Signatures: ${#SIGNATURES[@]}"

# Statistic Checking
echo -n "Amount of Packages equals amount of Signatures: "
if [ ${#PACKAGES[@]} -eq ${#SIGNATURES[@]} ]; then
    echo "yes"
else
    echo "error"
fi

# Database Checking
function verify_signature () {
	first=true
	for SIGNATURE in $@ ; do
		if ! gpg --verify "${SIGNATURE}" >/dev/null 2>&1 ; then
			if [ "${first}" == "true" ]; then
				echo "error"
				first=false
			fi 
			echo "${SIGNATURE} is invalid"
		fi
	done
}

echo -n "Database Signature enabled: "
if [ ${#DATABASE_SIGNATURE[@]} -eq 0 ]; then
    echo "no"
else
    echo "yes"
	echo ""
	echo -n "Verifying Database Signatures: "
	verify_signature ${DATABASE_SIGNATURE[@]}
fi
echo ""

echo -n "Files enabled: "
if [ ${#FILES[@]} -eq 0 ]; then
    echo "no"
else
    echo "yes"
	echo -n "Files Signature enabled: "
	if [ ${#FILES_SIGNATURE[@]} -eq 0 ]; then
		echo "no"
	else
		echo "yes"
		echo ""
		echo -n "Verifying Files Signatures: "
		verify_signature ${FILES_SIGNATURE[@]}
	fi
fi
echo ""

# Signature Checking
echo -n "Verifying Signatures: "
verify_signature ${SIGNATURES[@]}
echo ""

# Checking Compression
echo -n "Checking Compression: "
first=true
for PACKAGE in ${PACKAGES[@]}; do
	PACKAGE_RESULT=$(file "${PACKAGE}" | grep -v XZ)
	if [ -n "${PACKAGE_RESULT}" ]; then
		if [ "${first}" == "true" ]; then
			echo "error"
			first=false
		fi 
		echo "${PACKAGE_RESULT}"
	fi
done
echo ""

# Checking Duplicates
function check_duplicates () {
	first=true
	entry_names=()
	for ENTRY in $@ ; do
		if [[ ${ENTRY} =~ ${PACKAGE_REGEX} ]]; then
			entry_names+=("${BASH_REMATCH[1]}")
		fi
	done
	entry_names=($(echo "${entry_names[@]}" | tr " " "\n" | sort | uniq -cd))
	if [ ${#entry_names[@]} -ne 0 ]; then
		echo "error"
		echo "${entry_names[@]}" | tr " " "\n"
	else
		echo "ok"
	fi
}

echo -n "Checking Duplicate Packages: "
check_duplicates ${PACKAGES[@]}
echo ""

echo -n "Checking Duplicate Signatures: "
check_duplicates ${SIGNATURES[@]}
echo ""

# Checking database entries
function uncompress_database () {
	PACKAGE_RESULT=$(file "${1}" | grep -v XZ)
	if [ -n "${PACKAGE_RESULT}" ]; then
		echo "error"
		echo "${PACKAGE_RESULT}"
		return 1
	else 
		mkdir -p "${TMP_DB_PATH}"
		if tar -xf $1 -C "${TMP_DB_PATH}" ; then
			echo "yes"
		else
			echo "error - cannot extract"
			return 1
		fi
	fi
	return 0
}

function check_database_filenames () {
	OLDIFS=$IFS
	IFS=
	output=$(diff \
		<(find "${TMP_DB_PATH}" -name desc -exec sed "2q;d" {} \; | sort) \
		<(get_basename "${PACKAGES[@]}"))
	if [ $? -eq 0 ]; then
		echo "yes"
	else
		echo "error"
		echo ${output}
	fi
	IFS=$OLDIFS
}

function check_database_author () {
	OLDIFS=$IFS
	IFS=
	output=$(find "${TMP_DB_PATH}" \
			-name desc \
			-exec echo -n '{} - ' \; \
			-exec awk 'f{print;f=0} /%PACKAGER%/{f=1}' {} \; \
		| grep "Unknown Packager")
	if [ $? -eq 0 ]; then
		echo "error"
		echo ${output}
	else
		echo "yes"
	fi
	IFS=$OLDIFS
}

function get_basename () {
	for ENTRY in $@ ; do 
		basename "$ENTRY"
	done
}

echo -n "Database available: "
if [ ${#DATABASE[@]} -eq 1 ]; then
	echo "yes"
	echo -n "Database compressed: "
	if uncompress_database ${DATABASE[@]} ; then
		echo -n "Database filenames complete: "
		check_database_filenames
		echo ""
		echo -n "Database packager valid: "
		check_database_author
		echo ""
        echo "####################################################################"
	echo "##################### EVERYTHING IS GOOD TO GO #####################"
        echo "####################################################################"
        echo
        syncrepo.sh
	fi
elif [ ${#DATABASE[@]} -eq 0 ]; then
        echo "error - database not found"
else
	echo "error - multiple found"
fi
