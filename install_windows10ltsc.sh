#!/bin/bash

# URL de la ISO de Windows 10 LTSC
WINDOWS_ISO_URL="https://go.microsoft.com/fwlink/p/?LinkID=2195404&clcid=0x40a&culture=es-es&country=ES"

# Nombre de la imagen ISO descargada
WINDOWS_ISO="windows10-ltsc.iso"

# Tamaño del disco virtual en GB
DISK_SIZE=20G

# Nombre del disco virtual
DISK_IMG="windows10.img"

# URL de la ISO de los controladores VirtIO
VIRTIO_ISO_URL="https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/stable-virtio/virtio-win.iso"

# Nombre de la imagen ISO de VirtIO
VIRTIO_ISO="virtio-win.iso"

# Actualizar la lista de paquetes e instalar wget y qemu-utils
apt update
apt install -y wget qemu-utils

# Descargar la imagen ISO de Windows 10 LTSC
wget -O $WINDOWS_ISO $WINDOWS_ISO_URL

# Crear una imagen de disco virtual
qemu-img create -f raw $DISK_IMG $DISK_SIZE

# Descargar la imagen ISO de los controladores VirtIO
wget -O $VIRTIO_ISO $VIRTIO_ISO_URL

# Iniciar la instalación de Windows en una máquina virtual sin KVM, pero con soporte para AMD EPYC
qemu-system-x86_64 -cpu EPYC \
    -m 4G \
    -drive file=$DISK_IMG,format=raw \
    -cdrom $WINDOWS_ISO \
    -boot d \
    -device virtio-net,netdev=net0 \
    -netdev user,id=net0 \
    -drive file=$VIRTIO_ISO,media=cdrom

# Convertir la imagen de disco virtual a formato raw y copiarla al disco principal
qemu-img convert -O raw $DISK_IMG /dev/sda

# Reiniciar el VPS para arrancar desde el disco principal
reboot
