#!/bin/sh
cd luajit/src
#NDKDIR=$HOME/Android/Sdk/ndk/29.0.14206865
NDKDIR=$HOME/Android/Sdk/ndk/28.2.13676358

NDKBIN=$NDKDIR/toolchains/llvm/prebuilt/linux-x86_64/bin
NDKCROSS=$NDKBIN/i686-linux-android-
NDKCC=$NDKBIN/i686-linux-android35-clang

# not building
make clean
make \
	Q= \
	E="@:" \
	XCFLAGS=-DLUAJIT_ENABLE_LUA52COMPAT \
	TARGET_SONAME=libluajit.so \
	TARGET_DYLIBNAME=libluajit.dylib \
	TARGET_DLLNAME=luajit.dll \
	TARGET_DLLDOTANAME=libluajit.dll.a \
	\
	HOST_CC="gcc -m32" \
	CROSS=$NDKCROSS \
	STATIC_CC=$NDKCC \
	DYNAMIC_CC="$NDKCC -fPIC" \
	TARGET_LD=$NDKCC \
	TARGET_AR="$NDKBIN/llvm-ar rcus" \
	TARGET_STRIP="$NDKBIN/llvm-strip"

DESTDIR=../../../jniLibs/x86/
mkdir -p $DESTDIR
cp libluajit.so $DESTDIR
cp libluajit.a $DESTDIR
cp luajit $DESTDIR
