#!/bin/bash
# Install the headers/makefiles etc for building modules against
# It functions like kernel-devel package in RHEL/fedora or
# linux-headers package in Debian/Ubuntu
#  
#
# $$$$$$$$ By Curu Wong http://www.linuxplayer.org $$$$$$$$$
# Part of this script is copied and modified from
# fedora's kernel.srpm spec file
#
# This all looks scary, but the end result is supposed to be:
# * all arch relevant include/ files
# * all Makefile/Kconfig files
# * all script/ files
usage(){
	echo "Usage:"
	echo "INSTALL_PATH=/some/place $0"
	echo "or"
	echo "export INSTALL_PATH=/some/place"
	echo "$0"
}

if [ -z "$INSTALL_PATH" ]; then
  echo "INSTALL_PATH is not set"
  usage
  exit 1
fi
if [ \! -d "$INSTALL_PATH" ]; then
  echo "INSTALL_PATH '$INSTALL_PATH' is not a directory"
  usage
  exit 1
fi

if [ \! -f .missing-syscalls.d ]; then
  echo "Sorry, but you are not running me in kernel build directory,"
  echo "or you haven't built your kernel"
  echo "Please cd to it and then run me there, thanks!"
  exit 1
fi

KernelVer=`make -s kernelrelease`
KbuildDir=`pwd`
#the path of kernel-dev packages
#on Ubuntu, can be set to something like
#DevelDir="/usr/src/linux-headers-$KernelVer"
DevelDir="/usr/src/kernels/$KernelVer"
#if this directory is generated with make O=xxx option
if [ -h "source" ]; then
  out_tree="yes"
fi

echo "This may take a while, please wait..."
rm -f $INSTALL_PATH/lib/modules/$KernelVer/build
rm -f $INSTALL_PATH/lib/modules/$KernelVer/source
mkdir -p $INSTALL_PATH/lib/modules/$KernelVer/build
(cd $INSTALL_PATH/lib/modules/$KernelVer ; ln -s build source)
# dirs for additional modules per module-init-tools, kbuild/modules.txt
mkdir -p $INSTALL_PATH/lib/modules/$KernelVer/extra
mkdir -p $INSTALL_PATH/lib/modules/$KernelVer/updates
# first copy everything
if [ -z $out_tree ]; then
  cp --parents `find  -type f -name "Makefile*" -o -name "Kconfig*"` $INSTALL_PATH/lib/modules/$KernelVer/build
else
  (cd source; cp --parents `find  -type f -name "Makefile*" -o -name "Kconfig*"` $INSTALL_PATH/lib/modules/$KernelVer/build)
fi
cp Module.symvers $INSTALL_PATH/lib/modules/$KernelVer/build
cp System.map $INSTALL_PATH/lib/modules/$KernelVer/build
if [ -s Module.markers ]; then
  cp Module.markers $INSTALL_PATH/lib/modules/$KernelVer/build
fi
# then drop all but the needed Makefiles/Kconfig files
rm -rf $INSTALL_PATH/lib/modules/$KernelVer/build/Documentation
rm -rf $INSTALL_PATH/lib/modules/$KernelVer/build/scripts
rm -rf $INSTALL_PATH/l ib/modules/$KernelVer/build/include
cp .config $INSTALL_PATH/lib/modules/$KernelVer/build

### copy scripts ###
#change to the source directory if we build outside source tree
if [ -n "$out_tree" ]; then cd source; fi
cp -a scripts $INSTALL_PATH/lib/modules/$KernelVer/build
#copy architecture specific scripts
for arch_scripts in arch/*/scripts; do
  cp -a --parents $arch_scripts $INSTALL_PATH/lib/modules/$KernelVer/build/
done
#copy architecture specific *lds files
for arch_lds in arch/*/*lds; do
  cp -a --parents $arch_lds $INSTALL_PATH/lib/modules/$KernelVer/build/
done
#cd back to build dir
if [ -n "$out_tree" ]; then
  cd $KbuildDir
  #also copy scripts in build dir 
  cp -a scripts/ $INSTALL_PATH/lib/modules/$KernelVer/build
fi
#clean object files
rm -f $INSTALL_PATH/lib/modules/$KernelVer/build/scripts/*.o
rm -f $INSTALL_PATH/lib/modules/$KernelVer/build/scripts/*/*.o
# prune junk
find $INSTALL_PATH/lib/modules/$KernelVer/build/ -name ".*.cmd" -o -name "modules.order" -exec rm -f {} \;

###copy the kernel headers###
#change to the source directory if we build outside source tree
if [ -n "$out_tree" ]; then cd source; fi
#architecture specific headers 
for arch_include in arch/*/include; do
  cp -a --parents $arch_include $INSTALL_PATH/lib/modules/$KernelVer/build/
done
cp -a include $INSTALL_PATH/lib/modules/$KernelVer/build/include
#cd back to build dir
if [ -n "$out_tree" ]; then
  cd $KbuildDir
  #also copy include in build dir 
  cp -a include $INSTALL_PATH/lib/modules/$KernelVer/build/
fi

# Make sure the Makefile and version.h have a matching timestamp so that
# external modules can be built
touch -r $INSTALL_PATH/lib/modules/$KernelVer/build/Makefile $INSTALL_PATH/lib/modules/$KernelVer/build/include/linux/version.h
touch -r $INSTALL_PATH/lib/modules/$KernelVer/build/.config $INSTALL_PATH/lib/modules/$KernelVer/build/include/linux/autoconf.h
# Copy .config to include/config/auto.conf so "make prepare" is unnecessary.
cp $INSTALL_PATH/lib/modules/$KernelVer/build/.config $INSTALL_PATH/lib/modules/$KernelVer/build/include/config/auto.conf
# Move devel headers out of module path
mkdir -p `dirname $INSTALL_PATH/$DevelDir`
mv $INSTALL_PATH/lib/modules/$KernelVer/build $INSTALL_PATH/$DevelDir
ln -sf ../../..$DevelDir $INSTALL_PATH/lib/modules/$KernelVer/build

echo "Installed to $INSTALL_PATH"

