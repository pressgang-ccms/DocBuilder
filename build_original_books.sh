#!/bin/bash

TMP_DIR=/tmp/buildbooks
BOOKNAME=Book
EXPECTED_ARGS=2

if [ "$#" -lt ${EXPECTED_ARGS} ]
then
  echo ERROR! Expected more arguments.
	exit 1
fi

# Get the suffix on the directory
DIR_SUFFIX=$1
LOCK_FILE=${TMP_DIR}${DIR_SUFFIX}.lock

# echo ${LOCK_FILE}

shift

# Check and create a lock file to make sure builds don't overlap
if [ -f ${LOCK_FILE} ]
then
	date >> build_original_books_error.log
	echo "ERROR! ${LOCK_FILE} exists, consider increasing the time between builds." >> build_original_books_error.log
	exit 1
else
	touch ${LOCK_FILE}
fi

while (( "$#" ))
do
	# Extract the language and CSP id from the
	# command line argument
	CSPID=$1

	# Shift the arguments down
	shift

	# Start with a clean temp dir for every build
	if [ -d ${TMP_DIR}${DIR_SUFFIX} ]
	then
		rm -rf ${TMP_DIR}${DIR_SUFFIX}
	fi
	
	mkdir ${TMP_DIR}${DIR_SUFFIX}

	# Enter the temp directory
	pushd ${TMP_DIR}${DIR_SUFFIX}

		# Build the book as HTML-SINGLE with no overrides
		date > build.log

		echo "csprocessor build --flatten --flatten-topics --show-report --editor-links --permissive --output ${BOOKNAME}.zip ${CSPID} >> build.log"
		csprocessor build --flatten --flatten-topics --editor-links --permissive --output ${BOOKNAME}.zip ${CSPID} >> build.log
		
		CSP_STATUS=$? 
		
		# If the csp build failed then continue to the next item
		if [ $CSP_STATUS != 0 ]
		then
			if [ -d /var/www/html/${CSPID} ]
			then
				rm -rf /var/www/html/${CSPID}
			fi

			mkdir /var/www/html/${CSPID}
			cp build.log /var/www/html/${CSPID}

		else
			unzip ${BOOKNAME}.zip

			# The zip file will be extracted to a directory name that 
			# refelcts the name of the book. We don't know this name,
			# but we can loop over the subdirectories and then break
			# once we have processed the first directory.
			for dir in ./*/
			do
	
				# Enter the extracted book directory
				pushd ${dir}
	
					echo 'publican build --formats=html-single --langs=en-US &> publican.log'
	
					publican build --formats=html-single --langs=en-US &> publican.log
					
					PUBLICAN_STATUS=$?
	
					if [ -d /var/www/html/${CSPID} ] || [ -e /var/www/html/${CSPID} ]
					then
						rm -rf /var/www/html/${CSPID}
					fi
	
					mkdir /var/www/html/${CSPID}
					cp -R tmp/en-US/html-single/. /var/www/html/${CSPID}
	
					cp publican.log /var/www/html/${CSPID}
	
				popd
				
				# we only want to process one directory
				break
	
			done
	
			cp build.log /var/www/html/${CSPID}
		fi		

	popd
	
	# don't bother with the html or remark if the html-single failed
	if [ $PUBLICAN_STATUS == 0 ] && [ $CSP_STATUS == 0 ]
	then

		# Start with a clean temp dir for every build
		if [ -d ${TMP_DIR}${DIR_SUFFIX}html ]
		then
			rm -rf ${TMP_DIR}${DIR_SUFFIX}html
		fi
		
		mkdir ${TMP_DIR}${DIR_SUFFIX}html
	
		# Enter the temp directory
		pushd ${TMP_DIR}${DIR_SUFFIX}html
	
			# Build the book as HTML
			date > build.log
	
		 echo "csprocessor build --flatten --flatten-topics --show-report --editor-links --permissive --output ${BOOKNAME}.zip --override brand=PressGang-Websites --publican.cfg-override chunk_first=1 ${CSPID} >> build.log"
		 csprocessor build --flatten --flatten-topics --editor-links --permissive --output ${BOOKNAME}.zip --override brand=PressGang-Websites --publican.cfg-override chunk_first=1 ${CSPID} >> build.log
			
			# If the csp build failed then continue to the next item
			if [ $? != 0 ]
			then
				if [ -d /var/www/html/${CSPID}/html ]
				then
					rm -rf /var/www/html/${CSPID}/html
				fi
	
				mkdir /var/www/html/${CSPID}/html
				cp build.log /var/www/html/${CSPID}/html
	
			else
				unzip ${BOOKNAME}.zip
	
				# The zip file will be extracted to a directory name that 
				# refelcts the name of the book. We don't know this name,
				# but we can loop over the subdirectories and then break
				# once we have processed the first directory.
				for dir in ./*/
				do
		
					# Enter the extracted book directory
					pushd ${dir}
		
						echo 'publican build --formats=html --langs=en-US &> publican.log'
		
						publican build --formats=html --langs=en-US &> publican.log
		
						if [ -d /var/www/html/${CSPID}/html ] || [ -e /var/www/html/${CSPID}/html ]
						then
							rm -rf /var/www/html/${CSPID}/html
						fi
		
						mkdir /var/www/html/${CSPID}/html
						cp -R tmp/en-US/html/. /var/www/html/${CSPID}/html
		
						cp publican.log /var/www/html/${CSPID}/html
		
					popd
					
					# we only want to process one directory
					break
		
				done
		
				cp build.log /var/www/html/${CSPID}/html
			fi		
	
		popd	
	
		# Start with a clean temp dir for every build
		if [ -d ${TMP_DIR}${DIR_SUFFIX}remarks ]
		then
			rm -rf ${TMP_DIR}${DIR_SUFFIX}remarks
		fi
		
		mkdir ${TMP_DIR}${DIR_SUFFIX}remarks
	
		# Enter the temp directory
		pushd ${TMP_DIR}${DIR_SUFFIX}remarks	
		
			# Build the book with remarks enabled
			date > build.log
	
			echo "csprocessor build --flatten --flatten-topics --show-report --editor-links --permissive --output ${BOOKNAME}.zip --publican.cfg-override show_remarks=1 ${CSPID} >> build.log"
			csprocessor build --flatten --flatten-topics --editor-links --permissive --output ${BOOKNAME}.zip --publican.cfg-override show_remarks=1 ${CSPID} >> build.log
			
			# If the csp build failed then continue to the next item
			if [ $? != 0 ]
			then
				if [ -d /var/www/html/${CSPID}/remarks ]
				then
					rm -rf /var/www/html/${CSPID}/remarks
				fi
	
				mkdir /var/www/html/${CSPID}/remarks
				cp build.log /var/www/html/${CSPID}/remarks
	
			else
				unzip ${BOOKNAME}.zip
	
				# The zip file will be extracted to a directory name that 
				# refelcts the name of the book. We don't know this name,
				# but we can loop over the subdirectories and then break
				# once we have processed the first directory.
				for dir in ./*/
				do
		
					# Enter the extracted book directory
					pushd ${dir}
		
						echo 'publican build --formats=html-single --langs=en-US &> publican.log'
		
						publican build --formats=html-single --langs=en-US &> publican.log
		
						if [ -d /var/www/html/${CSPID}/remarks ] || [ -e /var/www/html/${CSPID}/remarks ]
						then
							rm -rf /var/www/html/${CSPID}/remarks
						fi
		
						mkdir -p /var/www/html/${CSPID}/remarks
						cp -R tmp/en-US/html-single/. /var/www/html/${CSPID}/remarks
		
						cp publican.log /var/www/html/${CSPID}/remarks
		
					popd
					
					# we only want to process one directory
					break
		
				done
		
				cp build.log /var/www/html/${CSPID}/remarks
			fi		
	
		popd	
	fi
done

# remove the lock file
rm -f ${LOCK_FILE}
