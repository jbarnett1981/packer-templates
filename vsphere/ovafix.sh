#!/bin/bash
ovas=(`ls *.ova`)
for ovafile in ${ovas[@]}
do
    name=${ovafile%".ova"}
    mkdir $name
    tar tf $ovafile > $name.txt
    sed -i '/nvram/d' $name.txt
    echo "Fixing $ovafile"
    tar xf $ovafile -C $name
    sed -i -E "/nvram/d" $name/*.ovf
    sed -i "/\.ovf/s/= .*/= `sha256sum $name/*.ovf |cut -d " " -f 1`/;/nvram/d" $name/*.mf
    sed -i "/\.vmdk/s/= .*/= `sha256sum $name/*.vmdk |cut -d " " -f 1`/;/nvram/d" $name/*.mf
    rm -f $name/*.nvram
    tar cf $ovafile -C $name/ -T $name.txt
done