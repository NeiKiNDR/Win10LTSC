#!/bin/bash

# Actualizar el sistema
apt update -y

# Instalar herramientas necesarias
apt install -y grub2 filezilla gparted wimtools qemu-utils wget

# URL de la ISO de Windows 10 LTSC
WINDOWS_ISO_URL="https://go.microsoft.com/fwlink/p/?LinkID=2195404&clcid=0x40a&culture=es-es&country=ES"

# URL de la ISO de los controladores VirtIO
VIRTIO_ISO_URL="https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/stable-virtio/virtio-win.iso"

# Nombre de la imagen ISO de Windows 10 LTSC
WINDOWS_ISO="windows10-ltsc.iso"

# Nombre de la imagen ISO de VirtIO
VIRTIO_ISO="virtio-win.iso"

# Tamaño del disco en GB (400GB)
DISK_SIZE_GB=400

# Crear la imagen de disco virtual
qemu-img create -f raw /dev/sda $((DISK_SIZE_GB * 1024))M

# Descargar la imagen ISO de Windows 10 LTSC
wget -O $WINDOWS_ISO $WINDOWS_ISO_URL

# Descargar la imagen ISO de los controladores VirtIO
wget -O $VIRTIO_ISO $VIRTIO_ISO_URL

# Montar la ISO de Windows 10 LTSC
mkdir /mnt/winiso
mount -o loop $WINDOWS_ISO /mnt/winiso

# Montar la ISO de VirtIO
mkdir /mnt/virtio
mount -o loop $VIRTIO_ISO /mnt/virtio

# Crear la tabla de particiones GPT
parted /dev/sda mklabel gpt

# Crear la partición EFI de 500MB
parted /dev/sda mkpart primary fat32 1MiB 500MiB
parted /dev/sda set 1 esp on

# Crear la partición para Windows
parted /dev/sda mkpart primary ntfs 500MiB 100%

# Formatear las particiones
mkfs.fat -F32 /dev/sda1
mkfs.ntfs -f /dev/sda2

# Montar la partición para Windows
mkdir /mnt/windows
mount /dev/sda2 /mnt/windows

# Copiar los archivos de instalación de Windows
rsync -av /mnt/winiso/* /mnt/windows/

# Desmontar la ISO de Windows
umount /mnt/winiso
rm -rf /mnt/winiso

# Copiar los controladores VirtIO
mkdir /mnt/windows/virtio
rsync -av /mnt/virtio/* /mnt/windows/virtio/

# Desmontar la ISO de VirtIO
umount /mnt/virtio
rm -rf /mnt/virtio

# Instalar GRUB para EFI
grub-install --target=x86_64-efi --efi-directory=/mnt/windows --boot-directory=/mnt/windows/boot --removable

# Crear el archivo de configuración de GRUB
cat <<EOF > /mnt/windows/boot/grub/grub.cfg
search --file --set=root /bootmgr
ntldr /bootmgr
boot
EOF

# Desmontar la partición de Windows
umount /mnt/windows

# Reiniciar el sistema para arrancar desde el disco principal
reboot
