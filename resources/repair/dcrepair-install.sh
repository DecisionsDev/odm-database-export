#!/bin/bash
if [ "$#" -ne 1 ]; then
    echo "pass the decisioncenter host url in parameter  [http(s)://host:port]"
    exit
fi

serverURL=$1
if [[ "$serverURL" == */ ]]
then
  separator=""
else
  separator="/"
fi
dc_assets=${serverURL}${separator}"decisioncenter/assets/decision-center-client-api.zip"
dcrepairapi="https://api.github.com/repos/DecisionsDev/odm-database-export/contents/resources/repair"
antbase="https://dlcdn.apache.org/ant/binaries/"


mkdir odm
cd odm

wget -O  assets.zip --no-check-certificate $dc_assets 
if [ $? -ne 0 ]
then
    echo "unable to install assets"
    cd ..
    exit
fi
jar xf assets.zip
if [ $? -ne 0 ]
then
    echo "unable to install assets"
    cd ..
    exit
fi
rm -f  assets.zip

# find the download url of the latest DC_Repair-<version>.zip published in the directory
dcrepairpath=$(wget -qO- --no-check-certificate $dcrepairapi | grep -o 'https://raw.githubusercontent.com/[^"]*/DC_Repair-[0-9][0-9._]*\.zip' | sort -u | awk '{k=$0; sub(/^.*DC_Repair-/,"",k); sub(/\.zip$/,"",k); gsub("_",".",k); print k, $0}' | sort -k1,1V | tail -1 | cut -d' ' -f2)
if [ -z "$dcrepairpath" ]
then
    echo "unable to find the repair scripts at $dcrepairapi"
    cd ..
    exit
fi
wget -O dcrepair.zip --no-check-certificate $dcrepairpath
if [ $? -ne 0 ]
then
    echo "unable to install repair scripts"
    cd ..
    exit
fi
cd teamserver/bin
jar xf ../../dcrepair.zip
if [ $? -ne 0 ]
then
    echo "unable to install repair scripts"
    cd ../../..
    exit
fi
cd ../..
rm -f dcrepair.zip
ant
if [ $? -ne 0 ]
then
  # dlcdn only hosts current releases, so look up the latest 1.10.x
  antzip=$(wget -qO- --no-check-certificate $antbase | grep -o 'apache-ant-1\.10\.[0-9]*-bin\.zip' | sort -uV | tail -1)
  if [ -z "$antzip" ]
  then
      echo "unable to find the latest ant version at $antbase"
      cd ..
      exit
  fi
  antdir=${antzip%-bin.zip}
  antdownload=${antbase}${antzip}
  wget -O ant.zip --no-check-certificate $antdownload
  if [ $? -ne 0 ]
  then
      echo "unable to install ant"
      cd ..
      exit
  fi
  jar xf ant.zip
  if [ $? -ne 0 ]
  then
      echo "unable to install ant"
      cd ..
      exit
  fi
  mv $antdir ant
  chmod a+x  ant/bin/*
  rm -f ant.zip
else
  echo "ant is already installed"
fi
cd ..
