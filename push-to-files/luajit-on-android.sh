#!/bin/bash
LUAJIT=/boot/home/config/non-packaged/bin/luajit-original
if [ $# = 0 ]
then
	$LUAJIT -e "require'ffi'.os='Haiku'" -i
else
	$LUAJIT -e "require'ffi'.os='Haiku'" "$@"
fi
