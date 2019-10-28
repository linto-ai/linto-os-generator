#!/bin/bash
INTERACTIVE=True

#check and creates dirs
if [ ! -d ./sdcard ]; then
  mkdir ./sdcard
fi

if [ ! -d ./sdcard/boot ]; then
  mkdir ./sdcard/boot
fi

#mount dirs
MNT=./sdcard
BOOT=./sdcard/boot

#commands
APTINSTALL_CMD="apt-get -y --force-yes install"
APTUPDATE_CMD="apt-get -y --force-yes update"
APTUPGRADE_CMD="apt-get -y --force-yes upgrade"

#args
IMAGE=$1
NEWIMAGE=$2

#################
### Functions ###
#################
calc_wt_size() {
  # NOTE: it's tempting to redirect stderr to /dev/null, so supress error
  # output from tput. However in this case, tput detects neither stdout or
  # stderr is a tty and so only gives default 80, 24 values
  WT_HEIGHT=30
  WT_WIDTH=$(tput cols)

  if [ -z "$WT_WIDTH" ] || [ "$WT_WIDTH" -lt 60 ]; then
    WT_WIDTH=80
  fi
  if [ "$WT_WIDTH" -gt 178 ]; then
    WT_WIDTH=120
  fi
  WT_MENU_HEIGHT=$(($WT_HEIGHT-7))
}

do_finish() {
  exit 0
}

do_exit() {
  exit 1
}

#tasks
do_copy_img() {
  echo "##############################"
  echo "# copying NEWIMAGE"
  echo "##############################"
  #check if origin_image exists
  if [ ! -f ${IMAGE} ]; then
    echo "ERROR: cannot find <origin_image.img>"; exit 1
  fi

  #check if new_image doesnt already exists
  if [ -f ${NEWIMAGE} ]; then
    echo "ERROR: file ${NEWIMAGE} already exists"; exit 1
  fi

  #copy
  echo "copying image file from origin..."
  cp -v ${IMAGE} ${NEWIMAGE}

  if [ -f ${NEWIMAGE} ]; then
    chown $USER ${NEWIMAGE}
    whiptail --msgbox "\
    Done.\n
    ${NEWIMAGE} was created. \
    " 20 70 1
  else
    echo "ERROR: error while copying <new_image.img>"; exit 1
  fi
}

do_increase_space() {
  if [ ! -f ${NEWIMAGE} ]; then
    echo "cannot find <new_image.img>"
    whiptail --msgbox "\
    Cannot find ${NEWIMAGE}
    Please run task 1.Copy ${NEWIMAGE} before.\
    " 20 70 1
    return
  fi

  echo "##############################"
  echo "# increasing size of NEWIMAGE"
  echo "##############################"
  echo -n "Actual size: "; ls -lh --block-size=M ${NEWIMAGE}
  echo -n "Enter size to add (in Mo): "; read input_variable

  #echo if input variable is a correct integer
  if [[ $input_variable =~ ^-?[0-9]+$ ]]; then
    echo "will add ${input_variable}Mo to ${NEWIMAGE}..."
  else
    echo "incorrect integer";
    exit 1
  fi

  #add space at the end
  dd if=/dev/zero bs=1M count=${input_variable} >> ${NEWIMAGE}
  # Get the starting offset of the root partition
  START_SECTOR=$(sudo parted ${NEWIMAGE} -ms unit s p | grep "^2" | cut -f 2 -d: | sed 's/[^0-9]//g')
  #repartition image partitions
fdisk ${NEWIMAGE} >> /dev/null 2>&1 <<EOF
d
2
n
p
2
$START_SECTOR

w
EOF
  sleep 3
  whiptail --msgbox "\
  Done.\
  " 10 10 1
}

do_check_and_resize() {
  if [ ! -f ${NEWIMAGE} ]; then
  echo "cannot find <new_image.img>"
  whiptail --msgbox "\
  Cannot find ${NEWIMAGE}
  Please run task 1.Copy ${NEWIMAGE} before.\
  " 10 70 1
  return
  fi

  echo "##############################"
  echo "# check and resize partition"
  echo "##############################"
  #loop0
  LOOP_ID=$(kpartx -avs ${NEWIMAGE} | grep -Eo '[0-9]+' | head -1)
  #check partition
  e2fsck -f /dev/mapper/loop${LOOP_ID}p2
  #resize partition
  resize2fs /dev/mapper/loop${LOOP_ID}p2
  #unmap loop0
  kpartx -d ${NEWIMAGE}
  sleep 3
  whiptail --msgbox "\
  Done.\
  " 10 10 1
}

do_prepare_fs() {
  if [ ! -f ${NEWIMAGE} ]; then
    echo "cannot find <new_image.img>"
    whiptail --msgbox "\
    Cannot find ${NEWIMAGE}
    Please run task 1.Copy ${NEWIMAGE} before.\
    " 10 70 1
    return
  fi

  echo "##############################"
  echo "# preparing fs"
  echo "##############################"
  #create directories
  if [ ! -d ${MNT} ]; then
    mkdir -p ${MNT}
  fi
  if [ ! -d ${BOOT} ]; then
    mkdir -p ${BOOT}
  fi

  # Mounting image
  LOOP_ID=$(kpartx -avs ${NEWIMAGE} | grep -Eo '[0-9]+' | head -1)
  mount /dev/mapper/loop${LOOP_ID}p2 ${MNT}
  mount /dev/mapper/loop${LOOP_ID}p1 ${BOOT}

  sleep 2

  #prepare for chroot
  mount -t proc chproc ${MNT}/proc
  mount -t sysfs chsys ${MNT}/sys
  mount -t devtmpfs chdev ${MNT}/dev
  mount -t devpts chpts ${MNT}/dev/pts
  cp /usr/bin/qemu-arm-static ${MNT}/usr/bin/.

  # Fix partition names
  cat << 'EOF' >> ${MNT}/etc/udev/rules.d/90-qemu.rules
KERNEL=="sda", SYMLINK+="mmcblk0"
KERNEL=="sda?", SYMLINK+="mmcblk0p%n"
KERNEL=="sda2", SYMLINK+="root"
EOF

  #temp fix DNS resolution for chroot
  echo "nameserver 8.8.8.8">>${MNT}/etc/resolv.conf

  #ld.so.preload
  if [ -f ${MNT}/etc/ld.so.preload ]; then
    mv ${MNT}/etc/ld.so.preload ${MNT}/root/.
    touch ${MNT}/etc/ld.so.preload
  fi

  whiptail --msgbox "\
  Done.
  \
  " 10 10 1
}

do_unprepare_fs() {
	echo "##############################"
	echo "# unpreparing fs"
	echo "##############################"

  echo "umouting dev/pts /dev /sys /proc..."
  sync
  sleep 2
  umount -l ${MNT}/dev/pts
  umount -l ${MNT}/dev
  umount -l ${MNT}/sys
  umount -l ${MNT}/proc
  echo "done"

  if [ -f ${MNT}/usr/bin/qemu-arm-static ]; then
    rm ${MNT}/usr/bin/qemu-arm-static
  fi

  # undo fix for qemu chroot
  if [ -f ${MNT}/etc/udev/rules.d/90-qemu.rules ]; then
    rm ${MNT}/etc/udev/rules.d/90-qemu.rules
  fi

  #restore ld.so.preload
  if [ -f ${MNT}/root/ld.so.preload ]; then
    rm ${MNT}/etc/ld.so.preload
    mv ${MNT}/root/ld.so.preload ${MNT}/etc/.
  fi

  #umount partitions
  echo "unmounting ${BOOT} ${MNT}..."
  umount -l ${BOOT}
  umount -l ${MNT}
  echo "done"
  sleep 2
  kpartx -d ${NEWIMAGE}

  #clean old files
  rm -rf ${MNT}/*
  mkdir ${MNT}/boot

  whiptail --msgbox "\
  Done.
  \
  " 10 10 1
}

do_mount() {
  #create directories
  if [ ! -d ${MNT} ]; then
    mkdir -p ${MNT}
  fi
  if [ ! -d ${BOOT} ]; then
    mkdir -p ${BOOT}
  fi

  LOOP_ID=$(kpartx -avs ${NEWIMAGE} | grep -Eo '[0-9]' | head -1)
  mount /dev/mapper/loop${LOOP_ID}p2 ${MNT}
  mount /dev/mapper/loop${LOOP_ID}p1 ${BOOT}
  whiptail --msgbox "\
  Done.
  \
  " 10 10 1
}

do_umount() {
  sync
  #umount
  umount ${BOOT}
  umount ${MNT}
  kpartx -d ${NEWIMAGE}

  #clean old files
  rm -rf ${MNT}/*
  mkdir ${MNT}/boot

  whiptail --msgbox "\
  Done.
  \
  " 10 10 1
}

do_replace_files() {
  RPLACEDIR=$1
  echo "##############################"
  echo "# Replace mode"
  echo "##############################"
  echo "replacing from ${RPLACEDIR} to ${MNT}..."

  #check if mounted ok
  if [ ! -d ${MNT}/home ]; then
    echo "not mounted, aborting"
    whiptail --msgbox "\
    not mounted, aborting...
    \
    " 10 60 1
    return
  fi

  #check if replace dir exists
  if [ ! -d ${RPLACEDIR} ]; then
    echo "missing directory ${RPLACEDIR}, aborting..."
    exit 1
  fi

  # Copying ${RPLACEDIR}/root_part/* in sdcard
  if [ -d ${RPLACEDIR}/root_part ]; then
    cp -Rv ${RPLACEDIR}/root_part/* ${MNT}
  fi
  #copying ${RPLACEDIR}/boot_part/* in boot sdcard
  if [ -d ${RPLACEDIR}/boot_part ]; then
    cp -Rv ${RPLACEDIR}/boot_part/* ${BOOT}
  fi

  echo "done"
}

do_enter_chroot() {
  echo "##############################"
  echo "# Entering chroot mode"
  echo "# type 'exit' to leave"
  echo "##############################"
  #check if mounted ok
  if [ ! -d ${MNT}/home ]; then
    echo "not mounted, aborting"
    whiptail --msgbox "\
    not mounted, aborting...
    \
    " 10 60 1
    return
  fi
  chroot ${MNT} /bin/uname -a
  chroot ${MNT} /bin/bash
  whiptail --msgbox "\
  Done.
  \
  " 10 10 1
}


######################################################################################
######################################################################################
######################################################################################

do_base() {
  SCRIPT=base.sh
  echo "#######################################"
  echo "# Install Base OS tweaks               "
  echo "#######################################"

  #check if we can chroot
  if [ ! -f ${MNT}/usr/bin/qemu-arm-static ]; then
    echo "missing qemu-arm-static, aborting..."
    whiptail --msgbox "\
    Please run task 4.Mount & Prepare partitions before.
    \
    " 10 60 1
    return
  fi

  #run
  do_replace_files base
  cp base/${SCRIPT} ${MNT}/root/.
  chroot ${MNT} /root/${SCRIPT}
  rm ${MNT}/root/${SCRIPT}
  echo "done"
}

do_install_client() {
  SCRIPT=client.sh
  echo "#######################################"
  echo "# Install Base OS tweeaks              "
  echo "#######################################"

  #check if we can chroot
  if [ ! -f ${MNT}/usr/bin/qemu-arm-static ]; then
    echo "missing qemu-arm-static, aborting..."
    whiptail --msgbox "\
    Please run task 4.Mount & Prepare partitions before.
    \
    " 10 60 1
    return
  fi

  #run
  cp client/${SCRIPT} ${MNT}/root/.
  chroot ${MNT} /root/${SCRIPT}
  rm ${MNT}/root/${SCRIPT}
  do_replace_files client
  echo "done"
}


do_install_openbox() {
  SCRIPT=install-openbox.sh
  echo "#######################################"
  echo "# Install x-windows and openbox script"
  echo "#######################################"

  #check if we can chroot
  if [ ! -f ${MNT}/usr/bin/qemu-arm-static ]; then
    echo "missing qemu-arm-static, aborting..."
    whiptail --msgbox "\
    Please run task 4.Mount & Prepare partitions before.
    \
    " 10 60 1
    return
  fi

  #run
  cp openbox/${SCRIPT} ${MNT}/root/.
  chroot ${MNT} /root/${SCRIPT}
  rm ${MNT}/root/${SCRIPT}
  do_replace_files openbox
  echo "done"
}


do_install_pulse_base() {
  SCRIPT=install-pulse-base.sh
  echo "#######################################"
  echo "# Install Pulse Audio for ReSpeaker    "
  echo "#######################################"

  #check if we can chroot
  if [ ! -f ${MNT}/usr/bin/qemu-arm-static ]; then
    echo "missing qemu-arm-static, aborting..."
    whiptail --msgbox "\
    Please run task 4.Mount & Prepare partitions before.
    \
    " 10 60 1
    return
  fi

  #run
  cp pulse_base/${SCRIPT} ${MNT}/root/.
  chroot ${MNT} /root/${SCRIPT}
  do_replace_files pulse_base
  echo "done"
}


do_install_linto_nest() {
  SCRIPT=install-linto.sh
  echo "#######################################"
  echo "# Install LinTO functional modules"
  echo "#######################################"

  #check if we can chroot
  if [ ! -f ${MNT}/usr/bin/qemu-arm-static ]; then
    echo "missing qemu-arm-static, aborting..."
    whiptail --msgbox "\
    Please run task 4.Mount & Prepare partitions before.
    \
    " 10 60 1
    return
  fi

  #run
  cp client_stack/${SCRIPT} ${MNT}/root/.
  chroot ${MNT} /root/${SCRIPT}
  rm ${MNT}/root/${SCRIPT}
  echo "done"
}

do_finalize_script() {
  SCRIPT=finalize.sh
  echo "##############################"
  echo "# Finalize script"
  echo "##############################"

  #check if we can chroot
  if [ ! -f ${MNT}/usr/bin/qemu-arm-static ]; then
    echo "missing qemu-arm-static, aborting..."
    whiptail --msgbox "\
    Please run task 4.Mount & Prepare partitions before.
    \
    " 10 60 1
    return
  fi

  #run
  cp ${SCRIPT} ${MNT}/root/.
  chroot ${MNT} /root/${SCRIPT}
  rm ${MNT}/root/${SCRIPT}

  #clean
  echo -e "Cleaning up filesystem"
  rm -rf ${MNT}/var/cache/apt/archives/*
  rm -rf ${MNT}/var/lib/apt/lists/*
  rm -f ${MNT}/var/log/*.log
  rm -f ${MNT}/var/log/apt/*.log
  rm -f ${MNT}/var/cache/apt/pkgcache.bin
  rm -rf ${MNT}/tmp/*

  echo "done"
}

do_install_production_patches() {
  SCRIPT=ipv4dhcpd.sh
  echo "##############################"
  echo "# Applying production patches"
  echo "##############################"

  #check if we can chroot
  if [ ! -f ${MNT}/usr/bin/qemu-arm-static ]; then
    echo "missing qemu-arm-static, aborting..."
    whiptail --msgbox "\
    Please run task 4.Mount & Prepare partitions before.
    \
    " 10 60 1
    return
  fi

  #run
  cp patchscripts/${SCRIPT} ${MNT}/root/.
  chroot ${MNT} /root/${SCRIPT}
  rm ${MNT}/root/${SCRIPT}

  #clean
  echo -e "Cleaning up filesystem"
  rm -rf ${MNT}/var/cache/apt/archives/*
  rm -rf ${MNT}/var/lib/apt/lists/*
  rm -f ${MNT}/var/log/*.log
  rm -f ${MNT}/var/log/apt/*.log
  rm -f ${MNT}/var/cache/apt/pkgcache.bin
  rm -rf ${MNT}/tmp/*

  echo "done"
}

## TODO
#      "43--> Install linto demonstrator" "from intern repositories" \
#      "44 --> Install linto demonstrator" "from public repositories" \
#       \
do_use_loop() {
if [ "$INTERACTIVE" = True ]; then
  calc_wt_size
  while true; do
    FUN=$(whiptail --title "generate images (generator.sh)" --menu "Setup Options" $WT_HEIGHT $WT_WIDTH $WT_MENU_HEIGHT --cancel-button Finish --ok-button Select \
      "1 Copy ${IMAGE}" "copy origin image to ${NEWIMAGE}" \
      "2 Increase size" "add space at the end of ${NEWIMAGE}" \
      "21 Check and resize" "check and resize / partition of ${NEWIMAGE}" \
      "3 Mount ${NEWIMAGE}" "mount only" \
      "31 Unmount ${NEWIMAGE}" "umount only" \
      "4  Mount & Prepare partitions" "mount and preprare filesystem before chroot" \
      "41 --> Install base OS tweaks" "Raspberry specific tweaks" \
      "42 --> Install LinTO client/server connectivity" "Mandatory for LinTO" \
      "43 --> Install OpenBox windows manager" "Required by GUI" \
      "44 --> Install PulseAudio base" "Required to use sound input/output" \
      "45 --> Install LinTO Functional modules" "GUI, hotword spotter... - requires 42 LinTO client/server" \
      "46 --> Connect to wifi" "Using wpa_supplicant" \
      "5 Unprepare & Umount partitions" "unpreprare and umount filesystem after chroot" \
      "6 Enter chroot" "enter chroot mode (need mounted and prepared)" \
      "7 Finalize image" "Before flash, Requires 4 - mount and prepare " \
      3>&1 1>&2 2>&3)
    RET=$?
    if [ $RET -eq 1 ]; then
      do_finish
    elif [ $RET -eq 0 ]; then
      case "$FUN" in
        1\ *) do_copy_img ;;
        2\ *) do_increase_space ;;
        21\ *) do_check_and_resize ;;
        3\ *) do_mount ;;
        31\ *) do_umount ;;
        4\ *) do_prepare_fs ;;
        41\ *) do_base ;;
        42\ *) do_install_client ;;
        43\ *) do_install_openbox ;;
        44\ *) do_install_pulse_base ;;
        45\ *) do_install_linto_nest ;;
        46\ *) do_replace_files wifi ;;
        5\ *) do_unprepare_fs ;;
        6\ *) do_enter_chroot ;;
        7\ *) do_finalize_script ;;
        *) whiptail --msgbox "Programmer error: unrecognized option" 20 60 1 ;;
      esac || whiptail --msgbox "There was an error running option $FUN" 20 60 1
    else
      exit 1
    fi
  done
fi
}

if [ $# -ne "2" ]; then
	echo "Usage : $0 <origin_image.img> <new_image.img>"
	exit 1
fi
if [ "$USER" != "root" ]; then
	echo "Script must be run as root"
	exit 1
fi

##################
### MAIN BEGIN ###
##################


do_use_loop
