#!/bin/bash

echo "copying chromedriver to ./usr/local/bin/ ..."
cp chromedriver ./usr/local/bin/

if ruby cityOfSDdownload.rb; then
    echo "unzipping file..."
    unzip ~/Downloads/2020_CSD.zip -d ~/Downloads

    sizeNewFile=$(wc -c <~/Downloads/efile_CSD_2020.xlsx)
    echo "size of the new file:" $sizeNewFile

    sizeOldFile=$(wc -c <downloads/static/efile_SD_CSD_2020.xlsx)
    echo "size of the old file:" $sizeOldFile

    if (( $sizeNewFile > $sizeOldFile )); then
        echo "removing file: downloads/static/efile_SD_CSD_2020.xlsx ..."
        rm downloads/static/efile_SD_CSD_2020.xlsx
        echo "moving efile_CSD_2020.xlsx to downloads/static directory ..."
        mv ~/Downloads/efile_CSD_2020.xlsx downloads/static/efile_SD_CSD_2020.xlsx
        echo "moving the zip file to downloads/static directory ..."
        mv ~/Downloads/2020_CSD.zip downloads/static/2020_CSD.zip
    else
        echo "ERROR: new file is not larger than the old file"
    fi
else
    echo "Download failed!"
fi
