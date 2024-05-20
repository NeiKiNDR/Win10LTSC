#!/bin/bash

# Actualizar y instalar paquetes necesarios
apt update -y
apt install wimtools -y

# Montar la ISO de virtio
mkdir -p /mnt/sources/virtio
mount -o loop /mnt/iso/virtio.iso /mnt/sources/virtio

# Verificar la estructura de la imagen WIM de virtio
if [ ! -d /mnt/sources/virtio/virtio_drivers ]; then
    echo "Error: No se encontró el directorio virtio_drivers en la imagen WIM."
    exit 1
fi

# Crear el archivo cmd.txt con los comandos necesarios
touch /mnt/sources/cmd.txt
echo 'add virtio /virtio_drivers' >> /mnt/sources/cmd.txt

# Actualizar el archivo boot.wim con los drivers virtio
wimlib-imagex update /mnt/sources/boot.wim 2 < /mnt/sources/cmd.txt

# Desmontar la ISO de virtio
umount /mnt/sources/virtio

echo "Actualización de drivers virtio completada."
