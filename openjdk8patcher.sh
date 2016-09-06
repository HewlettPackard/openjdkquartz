#!/bin/bash

echo 'This script modifies an openjdk installation to allow it to use the HPE Quartz performance emulator'

	if [ -z "$1" ]; then 
		echo usage: $0 valid openjdk8 source directory
		exit
	fi

	SRCD=$1
# Validation 1 - first parameter is a valid openjdk8 source directory
	if [[ -d "$SRCD" && -f "$SRCD/README" &&
		  (( `grep "This file should be located at the top of the OpenJDK Mercurial root" $SRCD/README | wc -l` == 1 )) ]]; then
		echo "Found valid openjdk source directory in supplied path: $SRCD"
	else
		echo "FATAL: couldn't find a valid openjdk source directory in supplied path: $SRCD"
		exit
	fi
# Validation 2 - Quartz exists on this machine and in the proper path

# 1. Modify hotspot files

	# Modify hotspot/make/linux/makefiles/vm.make: replace 'LIBS += -lm -ldl -lpthread' with 'LIBS += -lm -ldl -lnvmemul -lpthread'
	
	# Modify hotspot/src/share/vm/prims/nativeLookup.cpp :
		# 1. Add the row 'void JNICALL JVM_RegisterUnsafeMethods_p(JNIEnv *env, jclass unsafecls);' after the row 'void JNICALL JVM_RegisterUnsafeMethods(JNIEnv *env, jclass unsafecls);'
		# 2. Add the text ' { CC"Java_sun_misc_UnsafeFTM_registerNatives", NULL, FN_PTR(JVM_RegisterUnsafeMethods_p) },' after the text '{ CC"Java_java_lang_invoke_MethodHandleNatives_registerNatives", NULL, FN_PTR(JVM_RegisterMethodHandleMethods) },'
	# Add hotspot/src/share/vm/prims/unsafeFTM.cpp

	
#2. Modify jdk files

	# Modify jdk/make/java/java/FILES_java.gmk - add the row: '     java/nio/DirectByteBufferFTM.java \' after the row '     java/nio/DirectByteBuffer.java \'
	if [[ -f "$SRCD/jdk/make/java/java/FILES_java.gmk" ]]; then
		sed -i '/java\/nio\/DirectByteBuffer.java \\/a     java\/nio\/DirectByteBufferFTM.java \\' $SRCD/jdk/make/java/java/FILES_java.gmk
		echo "updated the file jdk/make/java/java/FILES_java.gmk"
	else 
		echo "jdk/make/java/java/FILES_java.gmk is missing, and was not updated"
	fi
	# Modify jdk/make/java/nio/FILES_java.gmk - add the row: '     java/nio/DirectByteBufferFTM.java \' after the row '     java/nio/StringCharBuffer.java \'
	if [[ -f "$SRCD/jdk/make/java/nio/FILES_java.gmk" ]]; then
		sed -i '/java\/nio\/DirectByteBuffer.java \\/a     java\/nio\/StringCharBuffer.java \\' $SRCD/jdk/make/java/nio/FILES_java.gmk
		echo "updated the file jdk/make/java/nio/FILES_java.gmk"
	else 
		echo "jdk/make/java/nio/FILES_java.gmk is missing, and was not updated"
	fi
	# Modify jdk/src/share/classes/java/nio/Buffer.java
	# Add jdk/src/share/classes/java/nio/DirectByteBufferFTM.java
	if [[ -f "./DirectByteBufferFTM.java" ]]; then
		cp ./DirectByteBufferFTM.java $SRCD/jdk/src/share/classes/java/nio/
		echo "added jdk/src/share/classes/java/nio/DirectByteBufferFTM.java"
	else
		echo "DirectByteBufferFTM.java is missing from current directory, and was not added"
	fi
	# Add jdk/src/share/classes/sun/misc/UnsafeFTM.java
	if [[ -f "./UnsafeFTM.java" ]]; then
		cp ./UnsafeFTM.java $SRCD/jdk/src/share/classes/sun/misc/
		echo "added jdk/src/share/classes/sun/misc/UnsafeFTM.java"
	else
		echo "UnsafeFTM.java is missing from current directory, and was not added"
	fi
	# Modify jdk/make/tools/sharing/classlist.linux - add row 'sun/misc/UnsafeFTM' after row 'sun/misc/Unsafe'
