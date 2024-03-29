#! /bin/bash

#
# Script for building Android arm64 Kernel
#
# Copyright (c) 2021 Fiqri Ardyansyah <fiqri15072019@gmail.com>
# Based on Panchajanya1999 script.
#

# Set environment for directory
WORKDIR="$(pwd)"
KERNEL_GIT="https://gitlab.com/playground7942706/kernel_xiaomi_sweet"
KERNEL_BRANCH="dev"
KERNEL_DIR="$WORKDIR/Phoenix"
IMG_DIR="$KERNEL_DIR"/out/arch/arm64/boot

git clone --depth=1 $KERNEL_GIT -b $KERNEL_BRANCH $KERNEL_DIR

cd $KERNEL_DIR

make clean && make mrproper

# Get defconfig file
DEFCONFIG=vendor/sweet_defconfig

# Set common environment
export KBUILD_BUILD_USER="Harikumar"
#
# Set if do you use GCC or clang compiler
# Default is clang compiler
#
#COMPILER=clang
COMPILER=aosp_clang

GIT_CLANG=false

# Get distro name
DISTRO=$(source /etc/os-release && echo ${NAME})

# Get all cores of CPU
PROCS=$(nproc --all)
export PROCS

# Get total RAM
RAM_INFO=$(free -m)
TOTAL_RAM=$(echo "$RAM_INFO" | awk '/^Mem:/{print $2}')
TOTAL_RAM_GB=$(awk "BEGIN {printf \"%.0f\", $TOTAL_RAM/1024}")
export TOTAL_RAM_GB

# Set date and time
DATE=$(TZ=Asia/Jakarta date)

# Set date and time for zip name
ZIP_DATE=$(TZ=Asia/Jakarta date +"%Y%m%d-%H%M")

# Get branch name
BRANCH=$(git rev-parse --abbrev-ref HEAD)
export BRANCH

# Check kernel version
KERVER=$(make kernelversion)

# Get last commit
COMMIT_HEAD=$(git log --oneline -1)

# Check directory path
# if [ -d "/root/project" ]; then
if [ -d "/home/runner/work" ]; then
	echo -e "Detected Continuous Integration dir"
	export LOCALBUILD=0
	export KBUILD_BUILD_VERSION="1"
	# Clone telegram script first
	git clone --depth=1 https://github.com/fabianonline/telegram.sh.git telegram
	# Set environment for telegram
	export TELEGRAM_DIR="$KERNEL_DIR/telegram/telegram"
  	export TELEGRAM_CHAT="-509071822"
   	export TELEGRAM_TOKEN=$(echo -n "MTg1ODgyNzEzNzpBQUZaVmFLT2pBaGpWeUNYZmlHZ0wtU0s2ZHA3X2xJTFpJRQ==" | base64 -d)
	# Get CPU name
	export CPU_NAME="$(lscpu | sed -nr '/Model name/ s/.*:\s*(.*) */\1/p')"
else
	echo -e "Detected local dir"
	export LOCALBUILD=1
fi

# Export build host name
if [ $LOCALBUILD == "0" ]; then
	export KBUILD_BUILD_HOST="GithubCI"
elif [ $LOCALBUILD == "1" ]; then
	export KBUILD_BUILD_HOST=$(uname -a | awk '{print $2}')
fi

# Cleanup KernelSU first on local build
if [[ -d "$KERNEL_DIR"/KernelSU && $LOCALBUILD == "1" ]]; then
	rm -rf KernelSU drivers/kernelsu
fi

# Set function for telegram
tg_post_msg() {
	"${TELEGRAM_DIR}" -H -D \
        "$(
            for POST in "${@}"; do
                echo "${POST}"
            done
        )"
}

tg_post_build() {
	"${TELEGRAM_DIR}" -H \
        -f "$1" \
        "$2"
}

# Set function for setup KernelSU
setup_ksu() {
	curl -kLSs "https://raw.githubusercontent.com/tiann/KernelSU/main/kernel/setup.sh" | bash -s main
	if [ -d "$KERNEL_DIR"/KernelSU ]; then
		git apply KernelSU-hook.patch
	else
		echo -e "Setup KernelSU failed, stopped build now..."
		exit 1
	fi
}


# Set function for defconfig changes
cfg_changes() {
	if [[ $PROCS -gt 4 && $TOTAL_RAM_GB -ge 8 ]]; then
		echo -e "Detected $PROCS core CPU and $TOTAL_RAM_GB GB RAM, this will enable compiler optimizations."
		if [ $COMPILER == "clang" ]; then
			sed -i 's/CONFIG_LTO_GCC=y/# CONFIG_LTO_GCC is not set/g' arch/arm64/configs/vendor/sweet_defconfig
			sed -i 's/CONFIG_GCC_GRAPHITE=y/# CONFIG_GCC_GRAPHITE is not set/g' arch/arm64/configs/vendor/sweet_defconfig
		elif [ $COMPILER == "gcc" ]; then
			sed -i 's/CONFIG_LTO=y/# CONFIG_LTO is not set/g' arch/arm64/configs/vendor/sweet_defconfig
			sed -i 's/CONFIG_LTO_CLANG=y/# CONFIG_LTO_CLANG is not set/g' arch/arm64/configs/vendor/sweet_defconfig
			sed -i 's/# CONFIG_LTO_NONE is not set/CONFIG_LTO_NONE=y/g' arch/arm64/configs/vendor/sweet_defconfig
   		elif [ $COMPILER == "aosp_clang" ]; then
			sed -i 's/CONFIG_LTO_GCC=y/# CONFIG_LTO_GCC is not set/g' arch/arm64/configs/vendor/sweet_defconfig
			sed -i 's/CONFIG_GCC_GRAPHITE=y/# CONFIG_GCC_GRAPHITE is not set/g' arch/arm64/configs/vendor/sweet_defconfig
   			sed -i 's/CONFIG_CC_STACKPROTECTOR_STRONG=y/# CONFIG_CC_STACKPROTECTOR_STRONG is not set/g' arch/arm64/configs/vendor/sweet_defconfig
		fi
  	elif [[ $PROCS -ge 4 && $TOTAL_RAM_GB -ge 8 ]]; then
		echo -e "Detected $PROCS core CPU and $TOTAL_RAM_GB GB RAM, this will disable compiler optimizations."
		if [ $COMPILER == "aosp_clang" ]; then
			sed -i 's/CONFIG_LTO_GCC=y/# CONFIG_LTO_GCC is not set/g' arch/arm64/configs/vendor/sweet_defconfig
			sed -i 's/CONFIG_GCC_GRAPHITE=y/# CONFIG_GCC_GRAPHITE is not set/g' arch/arm64/configs/vendor/sweet_defconfig
   			sed -i 's/CONFIG_CC_STACKPROTECTOR_STRONG=y/# CONFIG_CC_STACKPROTECTOR_STRONG is not set/g' arch/arm64/configs/vendor/sweet_defconfig
		fi
	elif [[ $PROCS -le 4 && $TOTAL_RAM_GB -lt 8 ]]; then
		echo -e "Detected $PROCS core CPU and $TOTAL_RAM_GB GB RAM, this will disable compiler optimizations."
		# Disable optimizations for Clang
		sed -i 's/CONFIG_LTO=y/# CONFIG_LTO is not set/g' arch/arm64/configs/vendor/sweet_defconfig
		sed -i 's/CONFIG_LTO_CLANG=y/# CONFIG_LTO_CLANG is not set/g' arch/arm64/configs/vendor/sweet_defconfig
		sed -i 's/# CONFIG_LTO_NONE is not set/CONFIG_LTO_NONE=y/g' arch/arm64/configs/vendor/sweet_defconfig
		# Disable optimizations for GCC
		sed -i 's/CONFIG_LTO_GCC=y/# CONFIG_LTO_GCC is not set/g' arch/arm64/configs/vendor/sweet_defconfig
		sed -i 's/CONFIG_GCC_GRAPHITE=y/# CONFIG_GCC_GRAPHITE is not set/g' arch/arm64/configs/vendor/sweet_defconfig
	fi
}

# Set function for cloning repository
clone() {
	# Clone AnyKernel3
	git clone --depth=1 https://github.com/fiqri19102002/AnyKernel3.git -b sweet

	if [ $COMPILER == "clang" ] && [ "$GIT_CLANG" = true ]; then
		# Clone Proton clang
		git clone --depth=1 https://gitlab.com/fiqri19102002/proton_clang-mirror.git clang
		# Set environment for clang
		TC_DIR=$KERNEL_DIR/clang
		# Get path and compiler string
		KBUILD_COMPILER_STRING=$("$TC_DIR"/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//')
		PATH=$TC_DIR/bin/:$PATH
	elif [ $COMPILER == "gcc" ] && [ "$GIT_CLANG" = true ]; then
		# Clone GCC ARM64 and ARM32
		git clone https://github.com/arter97/arm64-gcc.git --depth=1 gcc64
		git clone https://github.com/arter97/arm32-gcc.git --depth=1 gcc32
		# Set environment for GCC ARM64 and ARM32
		GCC64_DIR=$KERNEL_DIR/gcc64
		GCC32_DIR=$KERNEL_DIR/gcc32
		# Get path and compiler string
		KBUILD_COMPILER_STRING=$("$GCC64_DIR"/bin/aarch64-none-elf-gcc --version | head -n 1)
		PATH=$GCC64_DIR/bin/:$GCC32_DIR/bin/:/usr/bin:$PATH
  	elif [ $COMPILER == "aosp_clang" ] && [ "$GIT_CLANG" = true ]; then
		# Clone AOSP clang
    		git clone https://github.com/pkm774/android-kernel-tools.git -b tools --depth=1 clang
		# Set environment for clang
		TC_DIR=$KERNEL_DIR/clang/clang/host/linux-x86/clang-r428724
		GCC64_DIR=$KERNEL_DIR/clang/gcc/linux-x86/aarch64/aarch64-linux-android-4.9
		GCC32_DIR=$KERNEL_DIR/clang/gcc/linux-x86/arm/arm-linux-androideabi-4.9
		# Get path and compiler string
		KBUILD_COMPILER_STRING=$("$TC_DIR"/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//')
    		PATH=$TC_DIR/bin/:$GCC64_DIR/bin/:$GCC32_DIR/bin/:$PATH
      	elif [ $COMPILER == "aosp_clang" ] && [ "$GIT_CLANG" = false ]; then
		# Clone AOSP clang
    		ZYCLANG_DLINK="https://github.com/ZyCromerZ/Clang/releases/download/19.0.0git-20240216-release/Clang-19.0.0git-20240216.tar.gz"
      		mkdir -p $KERNEL_DIR/ZyClang
		aria2c -s16 -x16 -k1M $ZYCLANG_DLINK -o ZyClang.tar.gz
		tar -C $KERNEL_DIR/ZyClang/ -zxvf ZyClang.tar.gz
		rm -rf $KERNEL_DIR/ZyClang.tar.gz
		# Set environment for clang
		TC_DIR=$KERNEL_DIR/ZyClang
		GCC64_DIR=$KERNEL_DIR/ZyClang/aarch64-linux-gnu
		GCC32_DIR=$KERNEL_DIR/ZyClang/arm-linux-gnueabi
		# Get path and compiler string
		KBUILD_COMPILER_STRING=$("$TC_DIR"/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//')
    		PATH=$TC_DIR/bin/:$GCC64_DIR/bin/:$GCC32_DIR/bin/:$PATH
	fi

	export PATH KBUILD_COMPILER_STRING
}

# Set function for naming zip file
set_naming() {
	if [ -d "$KERNEL_DIR"/KernelSU ]; then
		KERNEL_NAME="Phoenix-sweet-ksu-personal-$ZIP_DATE"
		export ZIP_NAME="$KERNEL_NAME.zip"
	else
		KERNEL_NAME="Phoenix-sweet-personal-$ZIP_DATE"
		export ZIP_NAME="$KERNEL_NAME.zip"
	fi
}

# Set function for send messages to Telegram
send_tg_msg() {
	tg_post_msg "<b>Docker OS: </b><code>$DISTRO</code>" \
	            "<b>Kernel Version : </b><code>$KERVER</code>" \
	            "<b>Date : </b><code>$DATE</code>" \
	            "<b>Device : </b><code>Redmi Note 10 Pro (sweet)</code>" \
	            "<b>Pipeline Host : </b><code>$KBUILD_BUILD_HOST</code>" \
	            "<b>Host CPU Name : </b><code>$CPU_NAME</code>" \
	            "<b>Host Core Count : </b><code>$PROCS core(s)</code>" \
	            "<b>Host RAM Count : </b><code>$TOTAL_RAM_GB GB</code>" \
	            "<b>Compiler Used : </b><code>$KBUILD_COMPILER_STRING</code>" \
	            "<b>Branch : </b><code>$BRANCH</code>" \
	            "<b>Last Commit : </b><code>$COMMIT_HEAD</code>"
}

# Set function for starting compile
compile() {
	echo -e "Kernel compilation starting"
	make O=out "$DEFCONFIG"
	BUILD_START=$(date +"%s")
	if [ $COMPILER == "clang" ]; then
		if [ $LOCALBUILD == "0" ]; then
			make -j"$PROCS" O=out \
					CROSS_COMPILE=aarch64-linux-gnu- \
					LLVM=1
		elif [ $LOCALBUILD == "1" ]; then
			make -j"$PROCS" O=out \
					CROSS_COMPILE=aarch64-linux-gnu- \
					CROSS_COMPILE_COMPAT=arm-linux-gnueabi- \
					CC=clang \
					AR=llvm-ar \
					NM=llvm-nm \
					LD=ld.lld \
					OBJDUMP=llvm-objdump \
					STRIP=llvm-strip
		fi
  	elif [ $COMPILER == "aosp_clang" ] && [ "$GIT_CLANG" = true ]; then
		if [ $LOCALBUILD == "0" ]; then
			make -j"$PROCS" O=out \
					CROSS_COMPILE=aarch64-linux-gnu- \
					LLVM=1
		elif [ $LOCALBUILD == "1" ]; then
			make -j"$PROCS" O=out \
					CROSS_COMPILE=aarch64-linux-gnu- \
					CROSS_COMPILE_COMPAT=arm-linux-gnueabi- \
					CC=clang \
					AR=llvm-ar \
					NM=llvm-nm \
					LD=ld.lld \
					OBJDUMP=llvm-objdump \
					STRIP=llvm-strip
		fi
  	elif [ $COMPILER == "aosp_clang" ] && [ "$GIT_CLANG" = false ]; then
		if [ $LOCALBUILD == "0" ]; then
			make -j"$PROCS" O=out \
					CROSS_COMPILE=aarch64-linux-gnu- \
     					CROSS_COMPILE_ARM32=arm-linux-gnueabi- \
     					CC=clang \
					AR=llvm-ar \
					NM=llvm-nm \
					LD=ld.lld \
					OBJDUMP=llvm-objdump \
					STRIP=llvm-strip
		elif [ $LOCALBUILD == "1" ]; then
			make -j"$PROCS" O=out \
					CROSS_COMPILE=aarch64-linux-gnu- \
					CROSS_COMPILE_ARM32=arm-linux-gnueabi- \
					CC=clang \
					AR=llvm-ar \
					NM=llvm-nm \
					LD=ld.lld \
					OBJDUMP=llvm-objdump \
					STRIP=llvm-strip
		fi
	elif [ $COMPILER == "gcc" ]; then
		export CROSS_COMPILE_COMPAT=$GCC32_DIR/bin/arm-none-eabi-
		make -j"$PROCS" O=out CROSS_COMPILE=aarch64-none-elf-
	fi
	BUILD_END=$(date +"%s")
	DIFF=$((BUILD_END - BUILD_START))
	if [ -f "$IMG_DIR"/Image.gz-dtb ]; then
		echo -e "Kernel successfully compiled"
		if [ $LOCALBUILD == "1" ]; then
			git restore arch/arm64/configs/vendor/sweet_defconfig
			if [ -d "$KERNEL_DIR"/KernelSU ]; then
				git restore drivers/ fs/
			fi
		fi
	elif ! [ -f "$IMG_DIR"/Image.gz-dtb ]; then
		echo -e "Kernel compilation failed"
		if [ $LOCALBUILD == "0" ]; then
			tg_post_msg "<b>Build failed to compile after $((DIFF / 60)) minute(s) and $((DIFF % 60)) seconds</b>"
		fi
		if [ $LOCALBUILD == "1" ]; then
			git restore arch/arm64/configs/vendor/sweet_defconfig
			if [ -d "$KERNEL_DIR"/KernelSU ]; then
				git restore drivers/ fs/
			fi
		fi
		exit 1
	fi
}

# Set function for zipping into a flashable zip
gen_zip() {
	if [[ $LOCALBUILD == "1" || -d "$KERNEL_DIR"/KernelSU ]]; then
		cd AnyKernel3 || exit
		rm -rf dtbo/oss/dtbo.img dtb.img Image.gz-dtb *.zip
		cd ..
	fi

	# Move kernel image to AnyKernel3
	mv "$IMG_DIR"/dtb.img AnyKernel3/dtb.img
	mv "$IMG_DIR"/dtbo.img AnyKernel3/dtbo/oss/dtbo.img
	mv "$IMG_DIR"/Image AnyKernel3/Image.gz-dtb
	cd AnyKernel3 || exit

	# Archive to flashable zip
	zip -r9 "$ZIP_NAME" * -x .git README.md *.zip

	# Prepare a final zip variable
	ZIP_FINAL="$ZIP_NAME"

	if [ $LOCALBUILD == "0" ]; then
		tg_post_build "$ZIP_FINAL" "<b>Build took : $((DIFF / 60)) minute(s) and $((DIFF % 60)) second(s)</b>"
	fi

	if ! [[ -d "/home/fiqri" || -d "/root/project" ]]; then
		#curl -i -T *.zip https://oshi.at
		curl bashupload.com -T *.zip
	fi
	cd ..
}

clone
#cfg_changes
if [ $LOCALBUILD == "0" ]; then
	send_tg_msg
fi
compile
set_naming
gen_zip
setup_ksu
#cfg_changes
compile
set_naming
gen_zip
