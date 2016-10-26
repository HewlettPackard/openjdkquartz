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
# TODO Validation 2 - Quartz exists on this machine and in the proper path
	if [[ -f "/usr/lib/libnvmemul.so" ]]; then
		echo "Quartz exists on this machine"
	else
		echo "FATAL: Quartz doesn't exist on this machine, couldn't find the file /usr/lib/libnvmemul.so"
		exit
	fi

# 1. Modify hotspot files

	# TODO Modify hotspot/make/linux/makefiles/vm.make: replace 'LIBS += -lm -ldl -lpthread' with 'LIBS += -lm -ldl -lnvmemul -lpthread'
	if [[ -f "$SRCD/hotspot/make/linux/makefiles/vm.make" ]]; then
		sed -i '/LIBS += -lm -ldl -lpthread/c\LIBS += -lm -ldl -lnvmemul -lpthread' $SRCD/hotspot/make/linux/makefiles/vm.make
		echo "updated the file hotspot/make/linux/makefiles/vm.make"
	else 
		echo "hotspot/make/linux/makefiles/vm.make is missing, and was not updated"
	fi
	
	# TODO Modify hotspot/src/share/vm/prims/nativeLookup.cpp :
	if [[ -f "$SRCD/hotspot/src/share/vm/prims/nativeLookup.cpp" ]]; then
		# 1. Add the row 'void JNICALL JVM_RegisterUnsafeMethods_p(JNIEnv *env, jclass unsafecls);' after the row 'void JNICALL JVM_RegisterUnsafeMethods(JNIEnv *env, jclass unsafecls);'
		sed -i '/void JNICALL JVM_RegisterUnsafeMethods(JNIEnv \*env, jclass unsafecls);/avoid JNICALL JVM_RegisterUnsafeMethods_p(JNIEnv \*env, jclass unsafecls);' $SRCD/hotspot/src/share/vm/prims/nativeLookup.cpp
		# 2. Add the text ' { CC"Java_sun_misc_UnsafeFTM_registerNatives", NULL, FN_PTR(JVM_RegisterUnsafeMethods_p) },' after the text '{ CC"Java_java_lang_invoke_MethodHandleNatives_registerNatives", NULL, FN_PTR(JVM_RegisterMethodHandleMethods) },'
		sed -i '/{ CC"Java_java_lang_invoke_MethodHandleNatives_registerNatives", NULL, FN_PTR(JVM_RegisterMethodHandleMethods) },/a{ CC"Java_sun_misc_UnsafeFTM_registerNatives", NULL, FN_PTR(JVM_RegisterUnsafeMethods_p) },' $SRCD/hotspot/src/share/vm/prims/nativeLookup.cpp
		echo "updated the file hotspot/src/share/vm/prims/nativeLookup.cpp"
	else 
		echo "hotspot/src/share/vm/prims/nativeLookup.cpp is missing, and was not updated"
	fi
		
	# TODO Add hotspot/src/share/vm/prims/unsafeFTM.cpp
	if [[ -f "./UnsafeFTM.cpp" ]]; then
		cp ./UnsafeFTM.cpp $SRCD/hotspot/src/share/vm/prims/
		echo "added hotspot/src/share/vm/prims/UnsafeFTM.cpp"
	else
		echo "UnsafeFTM.cpp is missing from current directory, and was not added"
	fi

	
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
	# TODO Modify jdk/make/tools/sharing/classlist.linux - add row 'sun/misc/UnsafeFTM' after row 'sun/misc/Unsafe'
	if [[ -f "$SRCD/jdk/make/tools/sharing/classlist.linux" ]]; then
		sed -i '/sun\/misc\/Unsafe/a sun\/misc\/UnsafeFTM' $SRCD/jdk/make/tools/sharing/classlist.linux
		echo "updated the file jdk/make/tools/sharing/classlist.linux"
	else 
		echo "jdk/make/tools/sharing/classlist.linux is missing, and was not updated"
	fi
