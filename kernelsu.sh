#!/usr/bin/env sh
#
# GNU General Public License v3.0
# Copyright (C) 2023 MoChenYa mochenya20070702@gmail.com
#

WORKDIR="$(pwd)"

# ZyClang
# ZYCLANG_DLINK="https://github.com/ZyCromerZ/Clang/releases/download/17.0.0-20230725-release/Clang-17.0.0-20230725.tar.gz"
# ZYCLANG_DLINK="https://github.com/ZyCromerZ/Clang/releases/download/19.0.0git-20240203-release/Clang-19.0.0git-20240203.tar.gz"
# ZYCLANG_DLINK="https://github.com/llvm/llvm-project/releases/download/llvmorg-17.0.6/clang+llvm-17.0.6-aarch64-linux-gnu.tar.xz"

# ZYCLANG_DIR="$WORKDIR/ZyClang/bin"
ZYCLANG_DIR="$WORKDIR/ZyClang/sdclang/linux-x86_64/bin"
# ZYCLANG_DIR="$WORKDIR/ZyClang/clang+llvm-17.0.1-aarch64-linux-gnu/bin"

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

# COMPILER
#COMPILER=clang
COMPILER=sd_clang

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
# mkdir -p ZyClang
#aria2c -s16 -x16 -k1M $ZYCLANG_DLINK -o ZyClang.tar.gz
#tar -C ZyClang/ -zxvf ZyClang.tar.gz
#rm -rf ZyClang.tar.gz

# IF TAR.XZ
# mkdir -p ZyClang
# aria2c -s16 -x16 -k1M $ZYCLANG_DLINK -o ZyClang.tar.xz
# tar -C ZyClang/ -zxvf ZyClang.tar.xz
# rm -rf ZyClang.tar.xz

# SKIDDIE CLANG
#aria2c -s16 -x16 -k1M $ZYCLANG_DLINK -o ZyClang.tar.zst
#tar --use-compress-program=unzstd -xvf ZyClang.tar.zst -C $WORKDIR/ZyClang
#rm -rf ZyClang.tar.zst

# PROTON CLANG
# git clone https://gitlab.com/fiqri19102002/proton_clang-mirror.git -b main $WORKDIR/ZyClang

# SD CLANG
git clone https://github.com/ZyCromerZ/SDClang.git -b 14 $WORKDIR/ZyClang

# CLANG LLVM VERSIONS
CLANG_VERSION="$($ZYCLANG_DIR/clang --version | head -n 1)"
LLD_VERSION="$($ZYCLANG_DIR/ld.lld --version | head -n 1)"

msg " • 🌸 Cloning Kernel Source 🌸 "
git clone --depth=1 $KERNEL_GIT -b $KERNEL_BRANCHE $KERNEL_DIR
cd $KERNEL_DIR


# CLANG CONFIG PATCH
msg " • 🌸 Clang Config Patch 🌸 "
sed -i 's/CONFIG_LTO_GCC=y/# CONFIG_LTO_GCC is not set/g' $DEVICE_DEFCONFIG_FILE 
sed -i 's/CONFIG_GCC_GRAPHITE=y/# CONFIG_GCC_GRAPHITE is not set/g' $DEVICE_DEFCONFIG_FILE
sed -i 's/CONFIG_CC_STACKPROTECTOR_STRONG=y/# CONFIG_CC_STACKPROTECTOR_STRONG is not set/g' $DEVICE_DEFCONFIG_FILE
echo "❗❗❗➡️DONE⬅️❗❗❗"

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
	if [ $COMPILER == "clang" ]; then
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
	if [ $COMPILER == "sd_clang" ]; then
		args="PATH=$ZYCLANG_DIR:$PATH \
		      ARCH=arm64 \
		      SUBARCH=ARM64 \
              	      CROSS_COMPILE=aarch64-linux-gnu- \
	              CROSS_COMPILE_ARM32=arm-linux-gnueabi- \
	              CC=clang"
        fi
}
compile

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
