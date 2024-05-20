#!/bin/bash

# Actualizar y instalar paquetes necesarios
apt update -y
apt install grub2 filezilla gparted wimtools -y

# Obtener el tamaño del disco en GB y convertir a MB
disk_size_gb=$(parted /dev/sda --script print | awk '/^Disk \/dev\/sda:/ {print int($3)}')
disk_size_mb=$((disk_size_gb * 1024))

# Calcular el tamaño de la partición (25% del tamaño total)
part_size_mb=$((disk_size_mb / 4))

# Crear tabla de particiones GPT
parted /dev/sda --script mklabel gpt

# Crear dos particiones
parted /dev/sda --script mkpart primary ntfs 1MB ${part_size_mb}MB
parted /dev/sda --script mkpart primary ntfs ${part_size_mb}MB $((2 * part_size_mb))MB

# Informar al kernel sobre los cambios en la tabla de particiones
partprobe /dev/sda
sleep 10  # Asegurar que los cambios se propaguen

# Formatear las particiones
mkfs.ntfs -f /dev/sda1
mkfs.ntfs -f /dev/sda2

echo "NTFS partitions created"

# Instalar GRUB en la partición raíz
mount /dev/sda1 /mnt
grub-install --boot-directory=/mnt/boot /dev/sda

# Crear la configuración de GRUB
cat <<EOF > /mnt/boot/grub/grub.cfg
set timeout=5
menuentry "Windows 10 LTSC" {
    insmod part_gpt
    insmod ntfs
    search --no-floppy --set=root --label "Windows"
    ntldr /bootmgr
}
EOF

# Montar la ISO de Windows 10 LTSC y copiar los archivos
mkdir /mnt/iso
wget -O /mnt/iso/win10.iso https://dn790002.ca.archive.org/0/items/windows-10-enterprise-ltsc-2021-x-64-dvd-esp/Windows_10_enterprise_ltsc_2021_x64_dvd_es-es_51d721ea.iso
mount -o loop /mnt/iso/win10.iso /mnt/win

rsync -avz --progress /mnt/win/* /mnt

# Descargar y montar la ISO de virtio
wget -O /mnt/iso/virtio.iso https://shorturl.at/lsOU3
mkdir -p /mnt/sources/virtio  # Crear directorio sources/virtio si no existe
mount -o loop /mnt/iso/virtio.iso /mnt/virtio

rsync -avz --progress /mnt/virtio/* /mnt/sources/virtio

# Crear el archivo cmd.txt con los comandos necesarios
touch /mnt/sources/cmd.txt
echo 'add virtio /virtio_drivers' >> /mnt/sources/cmd.txt

# Actualizar el archivo boot.wim con los drivers virtio
wimlib-imagex update /mnt/sources/boot.wim 2 < /mnt/sources/cmd.txt

# Desmontar las ISOs
umount /mnt/win
umount /mnt/virtio

# Reiniciar la máquina
echo "Instalación finalizada. Reiniciando..."
