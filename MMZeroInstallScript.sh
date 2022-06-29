#!/bin/bash
#
# Copyright 2020 Achim Pieters | StudioPieters®
#
# More information on https://Studiopieters.nl
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NO NINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
# WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#

clone_with_git() {
    git -C "$2" pull || git clone https://github.com/$1.git "$2"
}
echo 'Downloading MagicMirror Raspberry Pi Zero W installation files'
clone_with_git oreoluwa/MagicZeroMirror MagicZeroMirror

echo 'Updating Pi'
sudo apt-get update;

echo 'Upgrading Pi'
sudo apt-get upgrade -y;
sudo apt-get upgrade --fix-missing -y;

NODE_VER=18.4.0
if ! node --version | grep -q ${NODE_VER}; then
  (cat /proc/cpuinfo | grep -q "Pi Zero") && if [ ! -d node-v${NODE_VER}-linux-armv6l ]; then
    echo "Installing nodejs ${NODE_VER} for armv6 from unofficial builds..."
    curl -O https://unofficial-builds.nodejs.org/download/release/v${NODE_VER}/node-v${NODE_VER}-linux-armv6l.tar.xz
    tar -xf node-v${NODE_VER}-linux-armv6l.tar.xz
  fi
  echo "Adding node to the PATH"
  PATH=$(pwd)/node-v${NODE_VER}-linux-armv6l/bin:${PATH}
fi

echo 'Installing Magic Mirror Dependencies'
cd ~;

echo 'Cloning the latest version of Magic Mirror2'
clone_with_git MichMich/MagicMirror MagicMirror

echo 'Installing Magic Mirror Dependencies'
cd MagicMirror;
npm install --arch=armv7l;
sudo apt install chromium-browser -y;
sudo apt-get install xinit -y;
sudo apt install xorg -y;
sudo apt install matchbox -y;
sudo apt install unclutter -y;

echo 'Loading default config'
cp config/config.js.sample config/config.js;

echo 'Set the splash screen to be magic mirror'
THEME_DIR="/usr/share/plymouth/themes"
sudo mkdir $THEME_DIR/MagicMirror;
sudo cp ~/MagicMirror/splashscreen/splash.png $THEME_DIR/MagicMirror/splash.png && sudo cp ~/MagicMirror/splashscreen/MagicMirror.plymouth $THEME_DIR/MagicMirror/MagicMirror.plymouth && sudo cp ~/MagicMirror/splashscreen/MagicMirror.script $THEME_DIR/MagicMirror/MagicMirror.script;
sudo plymouth-set-default-theme -R MagicMirror;

echo 'Copy Magic Mirror2 startup scripts'
cd ~;
mv ~/MagicZeroMirror/mmstart.sh ~/mmstart.sh;
mv ~/MagicZeroMirror/chromium_start.sh ~/chromium_start.sh;
mv ~/MagicZeroMirror/pm2_MagicMirror.json ~/pm2_MagicMirror.json;

chmod a+x mmstart.sh;
chmod a+x chromium_start.sh;
chmod pm2_MagicMirror.json;

echo 'Use pm2 control like a service MagicMirror'
cd ~;
npm install -g pm2;
pm2 startup;
sudo env PATH=$PATH:/home/pi/node-v${NODE_VER}-linux-armv6l/bin pm2 startup systemd -u pi --hp /home/pi
pm2 start pm2_MagicMirror.json;
pm2 save;
echo 'Magic Mirror should begin shortly'
