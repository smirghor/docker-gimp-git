#!/bin/bash

# dev setup

export DEBIAN_FRONTEND=noninteractive

apt-get -y update || exit
apt-get -y upgrade || exit
apt-get -y autoremove || exit

# tools
apt-get install -y \
	ca-certificates \
	git-core \
	wget \
	--no-install-recommends || exit

# common depends
apt-get install -y \
	autoconf \
	automake \
	build-essential \
	intltool \
	libglib2.0-0 \
	libglib2.0-dev \
	libtool \
	--no-install-recommends || exit
	
# babl depends
apt-get install -y \
	--no-install-recommends || exit

# gegl depends
# TODO: enable more
apt-get install -y \
	gtk-doc-tools \
	libgexiv2-2 \
	libgexiv2-dev \
	libgs9 \
	libgs-dev \
	libjson-glib-1.0-0 \
	libjson-glib-dev \
	libopenexr23 \
	libopenexr-dev \
	librsvg2-2 \
	librsvg2-dev \
	python \
	python-dev \
	python-gtk2 \
	python-gtk2-dev \
	python-cairo \
	python-cairo-dev \
	ruby \
	--no-install-recommends || exit

# libmypaint depends
apt-get install -y \
	libjson-c-dev \
	libjson-c3 \
	--no-install-recommends || exit

# gimp depends
apt-get install -y \
	autopoint \
	gettext \
	gtk-3-examples \
	libaa1 \
	libaa1-dev \
	libappstream-glib-dev \
	libasound2 \
	libasound2-dev \
	libbz2-1.0 \
	libbz2-dev \
	libexif12 \
	libexif-dev \
	libgtk2.0-0 \
	libgtk2.0-bin \
	libgtk2.0-dev \
	libgtk-3-dev \
	liblcms2-2 \
	liblcms2-dev \
	libmng1 \
	libmng-dev \
	libpoppler-glib8 \
	libpoppler-glib-dev \
	libtiff5 \
	libtiff5-dev \
	libwebkitgtk-1.0-0 \
	libwebkitgtk-dev \
	libwebp6 \
	libwebp-dev \
	libwmf0.2-7 \
	libwmf-dev \
	libxpm4 \
	libxpm-dev \
	mypaint-brushes \
	openexr \
	valac \
	xsltproc \
	--no-install-recommends || exit
	
unset DEBIAN_FRONTEND

# compile dir

export PREFIX=/usr/local
export PATH=$PREFIX/bin:$PATH
export PKG_CONFIG_PATH=$PREFIX/lib/pkgconfig:$PREFIX/share/pkgconfig

# get sources

export SRCDIR=/usr/src/gimp-git
mkdir -p $SRCDIR

cd $SRCDIR
git clone https://gitlab.gnome.org/GNOME/babl.git || exit
git clone https://gitlab.gnome.org/GNOME/gegl.git || exit
git clone https://github.com/mypaint/libmypaint.git || exit
git clone https://gitlab.gnome.org/GNOME/gimp.git || exit

# compile and install

# babl
cd $SRCDIR/babl
./autogen.sh --prefix=$PREFIX || exit
make -j`nproc` || exit
make install || exit

ldconfig || exit

# gegl
# depends: babl
cd $SRCDIR/gegl
./autogen.sh --prefix=$PREFIX || exit
make -j`nproc` || exit
make install || exit

ldconfig || exit

# libmypaint
# depends: gegl
cd $SRCDIR/libmypaint

git checkout libmypaint-v1
git config --global user.email "auto@example.com"
git config --global user.name "Automatic"
# backport for automake 1.16
git cherry-pick -x 40d9077a80be13942476f164bddfabe842ab2a45

./autogen.sh --prefix=$PREFIX || exit
./configure --disable-gegl || exit
make -j`nproc` || exit
make install || exit

ldconfig || exit

# gimp
cd $SRCDIR/gimp
./autogen.sh --prefix=$PREFIX --disable-gtk-doc || exit
make -j`nproc` || exit
make install || exit

ldconfig || exit

# final binary

ln -s `ls /usr/local/bin/gimp-?.* | head -n2` /usr/local/bin/gimp || exit

# dev cleanup

rm -rf $SRCDIR/*
rmdir $SRCDIR

dpkg -l | grep -- -dev | cut -d " " -f 3 | cut -d ":" -f 1 | sort -n | uniq | xargs apt-get -y purge

apt-get -y purge \
	autoconf \
	automake \
	build-essential \
	git-core \
	wget

apt-get -y autoremove
apt-get clean
rm -rf /var/lib/apt/lists/*

