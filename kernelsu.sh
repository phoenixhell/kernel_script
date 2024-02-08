#!/usr/bin/env sh
#
# GNU General Public License v3.0
# Copyright (C) 2023 MoChenYa mochenya20070702@gmail.com
#

WORKDIR="$(pwd)"

# COMPILER
COMPILER=aosp_clang
#COMPILER=proton_clang

# CLANG SOURCE
GIT_CLANG=true

# ZyClang
clang_clone() {
	if [ $COMPILER == "proton_clang" ] && [ "$GIT_CLANG" = false ]; then
		echo -e "Cloning Proton Clang"
		ZYCLANG_DLINK="https://huggingface.co/phoenix-1708/MAJIC/resolve/main/proton_clang.tar.gz"
	fi
 	if [ $COMPILER == "proton_clang" ] && [ "$GIT_CLANG" = true ]; then
		echo -e "Cloning AOSP Clang"
		ZYCLANG_DLINK="link here"
	fi
	if [ $COMPILER == "aosp_clang" ] && [ "$GIT_CLANG" = false ]; then
		echo -e "Cloning AOSP Clang"
		ZYCLANG_DLINK="https://huggingface.co/phoenix-1708/MAJIC/resolve/main/toolchain.tar.gz"
	fi
 	if [ $COMPILER == "aosp_clang" ] && [ "$GIT_CLANG" = true ]; then
		echo -e "Cloning AOSP Clang"
	fi
}
clang_clone

# Kernel Source
KERNEL_GIT="https://gitlab.com/playground7942706/android_kernel_xiaomi_sweet"
KERNEL_BRANCHE="dev"
KERNEL_DIR="$WORKDIR/Phoenix"

# Anykernel3
# ANYKERNEL3_GIT="https://github.com/pure-soul-kk/AnyKernel3"
# ANYKERNEL3_BRANCHE="master"
ANYKERNEL3_GIT="https://github.com/fiqri19102002/AnyKernel3"
ANYKERNEL3_BRANCHE="sweet"

# Build
DEVICES_CODE="sweet"
DEVICE_DEFCONFIG="vendor/sweet_defconfig"
DEVICE_DEFCONFIG_FILE="$KERNEL_DIR/arch/arm64/configs/$DEVICE_DEFCONFIG"
IMAGE="$KERNEL_DIR/out/arch/arm64/boot/Image.gz"
DTB="$KERNEL_DIR/out/arch/arm64/boot/dtb.img"
DTBO="$KERNEL_DIR/out/arch/arm64/boot/dtbo.img"

export KBUILD_BUILD_USER=Phoenix
export KBUILD_BUILD_HOST=GitHubCI

msg() {
	echo
	echo -e "\e[1;32m$*\e[0m"
	echo
}

cd $WORKDIR

# Download ZyClang
msg " • 🌸 Work on $WORKDIR 🌸"
msg " • 🌸 Cloning Toolchain 🌸 "

# DEFAULT TAR.GZ
clang_setup() {
	if [ $COMPILER == "proton_clang" ] && [ "$GIT_CLANG" = false ]; then
		echo -e "Cloning Proton Clang"
		mkdir -p ZyClang
		aria2c -s16 -x16 -k1M $ZYCLANG_DLINK -o ZyClang.tar.gz
		tar -C ZyClang/ -zxvf ZyClang.tar.gz
		rm -rf ZyClang.tar.gz
	fi
 	if [ $COMPILER == "proton_clang" ] && [ "$GIT_CLANG" = true ]; then
  		echo -e "Cloning Proton Clang"
    		git clone --depth=1 link -b branch ZyClang
      	fi
	if [ $COMPILER == "aosp_clang" ] && [ "$GIT_CLANG" = false ]; then
		echo -e "Cloning AOSP Clang"
		mkdir -p ZyClang
		aria2c -s16 -x16 -k1M $ZYCLANG_DLINK -o ZyClang.tar.gz
		tar -C ZyClang/ -zxvf ZyClang.tar.gz
		rm -rf ZyClang.tar.gz
	fi
 	if [ $COMPILER == "aosp_clang" ] && [ "$GIT_CLANG" = true ]; then
  		echo -e "Cloning AOSP Clang"
    		git clone --depth=1 https://gitlab.com/playground7942706/aosp_clang -b main ZyClang
      	fi
}
clang_setup

# ENV VAR SETUP
env_setup() {
	if [ $COMPILER == "proton_clang" ]; then
		echo -e "Cloning Proton Clang"
  		ZYCLANG_DIR="$WORKDIR/ZyClang/bin"
    	fi
     	if [ $COMPILER == "aosp_clang" ]; then
		echo -e "Cloning AOSP Clang"
  		#ZYCLANG_DIR="$WORKDIR/ZyClang/clang-r428724/bin"
		#GCC64="$WORKDIR/ZyClang/aarch64-linux-android-4.9/bin"
		#GCC32="$WORKDIR/ZyClang/arm-linux-androideabi-4.9/bin"
  		ZYCLANG_DIR="$WORKDIR/ZyClang/clang-r487747c/bin"
    		GCC64="$WORKDIR/ZyClang/aarch64-linux-android-4.14/bin"
		GCC32="$WORKDIR/ZyClang/arm-linux-androideabi-4.14/bin"
  	fi
}
env_setup

# CLANG LLVM VERSIONS
CLANG_VERSION="$($ZYCLANG_DIR/clang --version | head -n 1)"
LLD_VERSION="$($ZYCLANG_DIR/ld.lld --version | head -n 1)"

msg " • 🌸 Cloning Kernel Source 🌸 "
git clone --depth=1 $KERNEL_GIT -b $KERNEL_BRANCHE $KERNEL_DIR
cd $KERNEL_DIR


# CLANG GCC CONFIG PATCH
clang_gcc_patch() {
	if [ $COMPILER == "proton_clang" ]; then
		echo -e "Cloning Proton Clang"
		msg " • 🌸 Clang Config Patch 🌸 "
		sed -i 's/CONFIG_LTO_GCC=y/# CONFIG_LTO_GCC is not set/g' $DEVICE_DEFCONFIG_FILE 
		sed -i 's/CONFIG_GCC_GRAPHITE=y/# CONFIG_GCC_GRAPHITE is not set/g' $DEVICE_DEFCONFIG_FILE
		sed -i 's/CONFIG_CC_STACKPROTECTOR_STRONG=y/# CONFIG_CC_STACKPROTECTOR_STRONG is not set/g' $DEVICE_DEFCONFIG_FILE
  	fi
   	if [ $COMPILER == "aosp_clang" ]; then
		echo -e "Cloning Proton Clang"
  		sed -i 's/CONFIG_LTO=y/# CONFIG_LTO is not set/g' $DEVICE_DEFCONFIG_FILE
		sed -i 's/CONFIG_LTO_CLANG=y/# CONFIG_LTO_CLANG is not set/g' $DEVICE_DEFCONFIG_FILE
		sed -i 's/# CONFIG_LTO_NONE is not set/CONFIG_LTO_NONE=y/g' $DEVICE_DEFCONFIG_FILE
  		sed -i 's/CONFIG_CC_STACKPROTECTOR_STRONG=y/# CONFIG_CC_STACKPROTECTOR_STRONG is not set/g' $DEVICE_DEFCONFIG_FILE
    		sed -i 's/CONFIG_LTO_GCC=y/# CONFIG_LTO_GCC is not set/g' $DEVICE_DEFCONFIG_FILE 
		sed -i 's/CONFIG_GCC_GRAPHITE=y/# CONFIG_GCC_GRAPHITE is not set/g' $DEVICE_DEFCONFIG_FILE
  	fi
}
clang_gcc_patch
echo "❗❗❗➡️CONFIG PATCH DONE⬅️❗❗❗"

msg " • 🌸 Patching KernelSU 🌸 "
curl -LSs "https://raw.githubusercontent.com/tiann/KernelSU/main/kernel/setup.sh" | bash -s main
            echo "CONFIG_KPROBES=y" >> $DEVICE_DEFCONFIG_FILE
            echo "CONFIG_HAVE_KPROBES=y" >> $DEVICE_DEFCONFIG_FILE
            echo "CONFIG_KPROBE_EVENTS=y" >> $DEVICE_DEFCONFIG_FILE
KSU_GIT_VERSION=$(cd KernelSU && git rev-list --count HEAD)
KERNELSU_VERSION=$(($KSU_GIT_VERSION + 10000 + 200))
msg " • 🌸 KernelSU version: $KERNELSU_VERSION 🌸 "

# PATCH KERNELSU
msg " • 🌸 Applying patches || "

apply_patchs () {
for patch_file in $WORKDIR/patchs/*.patch
	do
	patch -p1 < "$patch_file"
done
}
apply_patchs

sed -i "/CONFIG_LOCALVERSION=\"/s/.$/-KSU-$KERNELSU_VERSION\"/" $DEVICE_DEFCONFIG_FILE

# BUILD KERNEL
msg " • 🌸 Started Compilation 🌸 "

# Set function for starting compile
compile() {
	echo -e "Kernel compilation starting"
	if [ $COMPILER == "proton_clang" ]; then
		args="PATH=$ZYCLANG_DIR:$PATH \
	            ARCH=arm64 \
	            SUBARCH=ARM64 \
	            CROSS_COMPILE=aarch64-linux-gnu- \
	            CROSS_COMPILE_COMPAT=arm-linux-gnueabi- \
	            CC=clang \
	            AR=llvm-ar \
	            NM=llvm-nm \
	            LD=ld.lld \
	            OBJDUMP=llvm-objdump \
	            STRIP=llvm-strip"
	fi 
	if [ $COMPILER == "aosp_clang" ]; then 	
		args="PATH=$ZYCLANG_DIR:$GCC64:$GCC32:$PATH \
		    ARCH=arm64 \
      		    SUBARCH=ARM64 \
	    	    CC=clang \
	            CLANG_TRIPLE=aarch64-linux-gnu- \
		    LLVM=1"
    fi
}
compile

: 'args="PATH=$ZYCLANG_DIR:$GCC64:$GCC32:$PATH \
		    ARCH=arm64 \
      		    SUBARCH=ARM64 \
	    	    CC=clang \
	            CLANG_TRIPLE=aarch64-linux-gnu- \
		    CROSS_COMPILE=aarch64-linux-android- \
		    CROSS_COMPILE_ARM32=arm-linux-androideabi- \
		    AR=llvm-ar \
		    NM=llvm-nm \
		    OBJCOPY=llvm-objcopy \
		    OBJDUMP=llvm-objdump \
		    READELF=llvm-readelf \
		    OBJSIZE=llvm-size \
	            STRIP=llvm-strip \
		    HOSTCC=clang \
		    HOSTCXX=clang++"  '

# LINUX KERNEL VERSION
rm -rf out
make O=out $args $DEVICE_DEFCONFIG
KERNEL_VERSION=$(make O=out $args kernelversion | grep "4.14")
msg " • 🌸 LINUX KERNEL VERSION : $KERNEL_VERSION 🌸 "
make O=out $args -j"$(nproc --all)"

msg " • 🌸 Packing Kernel 🌸 "

# INBUILT PACKING METHOD - DEFAULT
#cd $WORKDIR
#git clone --depth=1 $ANYKERNEL3_GIT -b $ANYKERNEL3_BRANCHE $WORKDIR/Anykernel3
#cd $WORKDIR/Anykernel3
#cp $IMAGE .
#cp $DTB $WORKDIR/Anykernel3/dtb
#cp $DTBO .

# MODIFIED PACKING METHOD
cd $WORKDIR
git clone --depth=1 $ANYKERNEL3_GIT -b $ANYKERNEL3_BRANCHE $WORKDIR/Anykernel3
cd $WORKDIR/Anykernel3
cp $IMAGE .
cp $DTB .
cp $DTBO $WORKDIR/AnyKernel3/dtbo/oss/dtbo.img

# PACK FILE
time=$(TZ='Asia/Kolkata' date +"%Y-%m-%d %H:%M:%S")
asia_time=$(TZ='Asia/Kolkata' date +%Y%m%d%H)
ZIP_NAME="Phoenix-$KERNEL_VERSION-KernelSU-$KERNELSU_VERSION.zip"
find ./ * -exec touch -m -d "$time" {} \;
zip -r9 $ZIP_NAME *
mkdir -p $WORKDIR/out && cp *.zip $WORKDIR/out

cd $WORKDIR/out
echo "
### Phoenix KERNEL With/Without KERNELSU
1. **Time** : $(TZ='Asia/Kolkata' date +"%Y-%m-%d %H:%M:%S") # Asian TIME
2. **Device Code** : $DEVICES_CODE
3. **LINUX Version** : $KERNEL_VERSION
4. **KERNELSU Version**: $KERNELSU_VERSION
5. **CLANG Version**: $CLANG_VERSION
6. **LLD Version**: $LLD_VERSION
" > RELEASE.md
echo "
### Phoenix KERNEL With/Without KERNELSU
1. **Time** : $(TZ='Asia/Kolkata' date +"%Y-%m-%d %H:%M:%S") # Asia TIME
2. **Device Code** : $DEVICES_CODE
3. **LINUX Version** : $KERNEL_VERSION
4. **KERNELSU Version**: $KERNELSU_VERSION
5. **CLANG Version**: ZyC clang version 18.0.0
6. **LLD Version**: LLD 18.0.0
" > telegram_message.txt
echo "Phoenix-$KERNEL_VERSION" > RELEASETITLE.txt
cat RELEASE.md
cat telegram_message.txt
cat RELEASETITLE.txt
msg "• 🌸 Done! 🌸 "
