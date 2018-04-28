#!/bin/bash

########################################################
#  Lazy kernel build script for OmniROM
#  for OnePlus 3T by SpasilliumNexus @ XDA Developers
########################################################

# Let us give this script some colors
ESC_SEQ="\x1b["
COL_RESET=$ESC_SEQ"39;49;00m"
COL_RED=$ESC_SEQ"31;01m"
COL_GREEN=$ESC_SEQ"32;01m"
COL_YELLOW=$ESC_SEQ"33;01m"
COL_BLUE=$ESC_SEQ"34;01m"
COL_MAGENTA=$ESC_SEQ"35;01m"
COL_CYAN=$ESC_SEQ"36;01m"

# Configure variables
THREAD=-j$(grep -c ^processor /proc/cpuinfo)
TOOLCHAIN_HOME=${HOME}/Android/toolchains/aarch64-linux-android-4.9/bin
OMNI_HOME=${HOME}/Development/android-kernels/omnirom
KERNEL_HOME=${HOME}/Development/android-kernels/omnirom/omni-android_kernel_oneplus_msm8996
OUTPUT_HOME=${HOME}/Development/android-kernels/omnirom/omni-android_kernel_oneplus_msm8996-output
ZIMAGE_HOME=$OUTPUT_HOME/arch/arm64/boot
KERNEL_IMAGE=$ZIMAGE_HOME/Image.gz-dtb
OP3_DEFCONFIG=omni_oneplus3_defconfig
DTB_IMAGE=dtb
ARM_ARCH=arm64
BUILD_USER=spasilliumnexus
BUILD_HOST=satellite
REPACK_HOME=${HOME}/Android/anykernel2
REPACK_OUTPUT=${HOME}/Android/anykernel2-output
ZIPPED_OUTPUT=${HOME}/Development/android-kernels/omnirom/omni-android_kernel_oneplus_msm8996-completed

# Configure kernel naming and versioning
########################################################################
# MAKE SURE THE INFO HERE AND IN DEFCONFIG ARE THE SAME FOR CONSISTENCY
########################################################################
ROMNAME=OmniROM
CKERNEL="Custom Kernel"
CREATOR=SpasilliumNexus
K_NAME=omni
K_TYPE=custom_kernel
K_VERSION=8.1.0
K_DEVICE=oneplus3
K_DEVICE2="OnePlus 3(T)"
K_RELEASE=${K_NAME}-${K_VERSION}-$(date -u +%Y%m%d)-${K_DEVICE}-${K_TYPE}
CHANGELOG=${K_RELEASE}-changelog.txt

# Clear out the Terminal
reset

# Title this script in Terminal
echo -e $COL_BLUE"$ROMNAME Easy Custom Kernel Compiler\nFor $K_DEVICE2 by $CREATOR @ XDA Developers"$COL_RESET
echo
sleep 2
echo -e $COL_YELLOW"Version of the kernel to be compiled: \e[31m$K_VERSION - $K_DEVICE2"$COL_RESET
echo
sleep 2

function quit_script {
  echo "Goodbye."
  exit 0
}

function clean_source {
  echo -e $COL_RED"Cleaning out previous kernel compilation..."$COL_RESET
  echo
  make -C $KERNEL_HOME ARCH=$ARM_ARCH clean
  make -C $KERNEL_HOME ARCH=$ARM_ARCH mrproper
  rm -rf $OUTPUT_HOME
  rm -rf $REPACK_OUTPUT
  mkdir $OUTPUT_HOME
}

function confirm_build {
  # Configure exports for compiling
  echo -e $COL_RED"Configuring exports for kernel compilation"$COL_RESET
  echo
  sleep 2
  export PATH=$TOOLCHAIN_HOME:$PATH
  export CROSS_COMPILE=$TOOLCHAIN_HOME/aarch64-linux-android-
  export ARCH=arm64
  export SUBARCH=arm64
  export KBUILD_BUILD_USER=$BUILD_USER
  export KBUILD_BUILD_HOST=$BUILD_HOST
  export CCACHE=ccache

  # Here is the start process of the kernel compilation process
  DATE_START=$(date +"%s")

  # Begin kernel compilation
  echo -e $COL_BLUE"Beginning compilation of $K_RELEASE"$COL_RESET
  echo
  make -C $KERNEL_HOME O=$OUTPUT_HOME ARCH=$ARM_ARCH KBUILD_BUILD_USER=$BUILD_USER KBUILD_BUILD_HOST=$BUILD_HOST $OP3_DEFCONFIG
  make -C $KERNEL_HOME O=$OUTPUT_HOME ARCH=$ARM_ARCH KBUILD_BUILD_USER=$BUILD_USER KBUILD_BUILD_HOST=$BUILD_HOST $THREAD
  cp -r $REPACK_HOME $REPACK_OUTPUT
  cp -vr $KERNEL_IMAGE $REPACK_OUTPUT/zImage

  # Generate a changelog to go along with the release
  echo -e $COL_BLUE"Generating changelog of the last 7 days for $K_RELEASE..."$COL_RESET
  echo
  if [ ! -d $ZIPPED_OUTPUT ]; then
    mkdir $ZIPPED_OUTPUT
  fi
  touch $ZIPPED_OUTPUT/$CHANGELOG
  for i in $(seq 7);
    do
      export DATE_AFTER=`date --date="$i days ago" +%m-%d-%Y`
      k=$(expr $i - 1)
      export DATE_UNTIL=`date --date="$k days ago" +%d-%b-%Y`
      echo  $DATE_UNTIL    >> $ZIPPED_OUTPUT/$CHANGELOG;
      echo '===============' >> $ZIPPED_OUTPUT/$CHANGELOG;
      git log --pretty=format:'%h  %s -[%an]' --decorate --after=$DATE_AFTER --until=$DATE_UNTIL >> $ZIPPED_OUTPUT/$CHANGELOG
      echo >> $ZIPPED_OUTPUT/$CHANGELOG;
    echo >> $ZIPPED_OUTPUT/$CHANGELOG;
  done

  # Move the completed dtb to AnyKernel2
  echo -e $COL_BLUE"Copying dtb image to AnyKernel2 for packing"$COL_RESET
  echo
  cp $KERNEL_IMAGE $REPACK_OUTPUT/zImage

  # Begin AnyKernel2 zip creation
  echo -e $COL_BLUE"Creating zip file of $K_RELEASE with AnyKernel2..."$COL_RESET
  echo
  cd $REPACK_OUTPUT
  sed -i "/kernel.string=/c\kernel.string=$ROMNAME $K_VERSION $CKERNEL by $CREATOR" $REPACK_OUTPUT/anykernel.sh
  zip -r9 $K_RELEASE.zip *
  
  # Move the created zip to completed folder
  mv $K_RELEASE.zip $ZIPPED_OUTPUT/$K_RELEASE.zip
  cd $OMNI_HOME

  # And here is the end process of the kernel compilation process
  echo
  DATE_END=$(date +"%s")
  DIFF=$(($DATE_END - $DATE_START))
  echo -e $COL_GREEN"Compilation time: $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds."$COL_RESET
  echo
  echo -e $COL_GREEN"The newly created zip can be found in /Development/android-kernels/omnirom/omni-android_kernel_oneplus_msm8996-completed."$COL_RESET
  echo
}


# Confirm cleaning of kernel source selection
if [ "$(ls -A $OUTPUT_HOME)" ]; then
  while read -p "Do you want to clean out the source before building? (yes/no/quit) " dchoice
    do
      case "$dchoice" in
        y|Y|yes|Yes )
        clean_source
        break
        ;;
        n|N|no|No )
        break
        ;;
        q|Q|quit|Quit )
        quit_script
        ;;
        * )
        echo "Invalid input. Please choose again."
        sleep 2
        ;;
    esac
  done
fi


# Confirm compiling of kernel source selection
while read -p "Do you want to begin compiling the kernel (yes), or do you want to start over (no)? (yes/no/quit) " dchoice
  do
    case "$dchoice" in
      y|Y|yes|Yes )
      confirm_build
      break
      ;;
      n|N|no|No|NO )
      echo "Starting over. . ."
      sleep 2
      exec bash "$0"
      ;;
      q|Q|quit|Quit )
      quit_script
      ;;
      * )
      echo "Invalid input. Please choose again."
      sleep 2
      ;;
  esac
done
