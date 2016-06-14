#!/bin/bash
#
#	SURPI_setup.sh
#
#	This script will install SURPI and its dependencies. It has been tested with Ubuntu 12.04.
#	The script has been designed to work on a newly installed OS, though should also work on an existing system.
#
#	Several Ubuntu packages are installed, as well as some perl modules - please inspect the code if you have concerns
#	about these installations on an existing system.
#
#	SURPI is sensitive to the use of specific versions of its software dependencies. We will likely work to validate
#	new versions over time, but currently we are using specific versions for these dependencies. These versions may
#	conflict with versions on an existing system.
#
#	Chiu Laboratory
#	University of California, San Francisco
#	January, 2014
#
# Copyright (C) 2014 Scot Federman - All Rights Reserved
# Permission to copy and modify is granted under the BSD license
# Last revised 6/6/2014

export DEBIAN_FRONTEND=noninteractive

#Change below folders as desired in order to change installation location.
install_folder="/usr/local"
bin_folder="$install_folder/bin"

if [ ! -d $bin_folder ]
then
	mkdir $bin_folder
fi

CWD=$(pwd)

#
##
### install & update Ubuntu packages
##
#

# Install packages necessary for the SURPI pipeline.
sudo -E apt-get update -y
sudo -E apt-get install -y qt-sdk make csh htop python-dev gcc unzip g++ g++-4.6 cpanminus ghostscript blast2 python-matplotlib git pigz parallel ncbi-blast+
sudo -E apt-get upgrade -y

#
##
### install EC2 CLI tools
##
#

sudo -E apt-get install -y openjdk-7-jre
wget http://s3.amazonaws.com/ec2-downloads/ec2-api-tools.zip
sudo mkdir /usr/local/ec2
sudo unzip ec2-api-tools.zip -d /usr/local/ec2

echo "export JAVA_HOME=/usr/lib/jvm/java-7-openjdk-amd64/jre" >> ~/.zshrc
echo "export EC2_HOME=/usr/local/ec2/ec2-api-tools-1.7.5.1" >> ~/.zshrc
echo "PATH=\$PATH:$EC2_HOME/bin" >> ~/.zshrc

#
##
### install Perl Modules
##
#

# for taxonomy
sudo cpanm DBI
sudo cpanm DBD::SQLite

# for twitter updates
sudo cpanm Net::Twitter::Lite::WithAPIv1_1
sudo cpanm Net::OAuth


#
##
### install SURPI scripts
##
#

#Install specific version
version="surpi-1.0.18"
wget "https://github.com/chiulab/surpi/releases/download/v1.0.18/$version.tar.gz"
tar xvfz $version.tar.gz
sudo mv $version "$bin_folder/"
sudo ln -s "$bin_folder/$version" "$bin_folder/surpi"

echo "PATH=\$PATH:$bin_folder/surpi" >> ~/.zshrc

#
##
### install gt (genometools)
##
#
#Works in Ubuntu 14.10
curl -O "http://genometools.org/pub/genometools-1.5.7.tar.gz"
tar xvfz genometools-1.5.7.tar.gz
cd genometools-1.5.7
make 64bit=yes curses=no cairo=no
sudo make "prefix=$install_folder" 64bit=yes curses=no cairo=no install
cd "$CWD"

#
##
### install seqtk
##
#
wget "https://github.com/lh3/seqtk/archive/v1.2.tar.gz"
tar xvfz v1.2.tar.gz
cd seqtk-1.2
make
sudo mv seqtk "$bin_folder/"
cd $CWD

#
##
### install fastq
##
#
mkdir fastq
cd fastq
wget "https://raw.github.com/brentp/bio-playground/master/reads-utils/fastq.cpp"
g++ -O2 -o fastq fastq.cpp
sudo mv fastq "$bin_folder/"
sudo chmod +x "$bin_folder/fastq"
cd $CWD

#
##
### install fqextract
##
#
mkdir fqextract
cd fqextract
wget https://raw.github.com/attractivechaos/klib/master/khash.h
wget http://chiulab.ucsf.edu/SURPI/software/fqextract.c
gcc fqextract.c -o fqextract
sudo mv fqextract "$bin_folder/"
sudo chmod +x "$bin_folder/fqextract"
cd $CWD

#
##
### install cutadapt
##
#
version="1.9.1"
wget --no-check-certificate https://github.com/marcelm/cutadapt/archive/v$version.tar.gz -O cutadapt-$version.tar.gz
tar xvfz cutadapt-$version.tar.gz
cd cutadapt-$version
python setup.py build
sudo python setup.py install
cd $CWD

#
##
### install prinseq-lite.pl
##
#
version="0.20.4"
wget http://nbtelecom.dl.sourceforge.net/project/prinseq/standalone/prinseq-lite-$version.tar.gz
tar xvfz prinseq-lite-$version.tar.gz
sudo cp prinseq-lite-$version/prinseq-lite.pl "$bin_folder/"
sudo chmod +x "$bin_folder/prinseq-lite.pl"

#
##
### compile and install dropcache (must be after SURPI scripts)
##
#

sudo gcc $bin_folder/surpi/source/dropcache.c -o dropcache
sudo mv dropcache "$bin_folder/"
sudo chown root "$bin_folder/dropcache"
# let the none root user can execute this command
sudo chmod u+s "$bin_folder/dropcache"

#
##
### install SNAP
##
#
wget --no-check-certificate https://github.com/amplab/snap/releases/download/v1.0beta.18/snap-aligner
sudo mv snap-aligner $bin_folder
sudo chmod +x $bin_folder/snap-aligner
sudo chown root:root $bin_folder/snap-aligner

#
##
### install RAPSearch
##
#

wget --no-check-certificate "https://github.com/zhaoyanswill/RAPSearch2/archive/master.zip" -O RAPSearch2-master.zip
unzip RAPSearch2-master.zip
cd RAPSearch2-master
./install
sudo cp bin/* $bin_folder/
cd $CWD

#
##
### install fastQValidator from sourcecode
##
#
# http://genome.sph.umich.edu/wiki/fastQValidator

version="0.1.1"
wget --no-check-certificate https://github.com/statgen/fastQValidator/archive/v$version.tar.gz -O fastQValidator-$version.tar.gz
tar xvzf fastQValidator-$version.tar.gz
# download the libStatGen package
git clone https://github.com/statgen/libStatGen.git
cd fastQValidator-$version
make all
sudo cp bin/fastQValidator "$bin_folder/"
cd $CWD


# Installation notes for blat version 34
# http://www.vcru.wisc.edu/simonlab/bioinformatics/programs/install/blat.htm
ver="34"
wget -N http://users.soe.ucsc.edu/~kent/src/blatSrc$ver.zip -O blatSrc-$ver.zip
unzip blatSrc-$ver.zip
cd blatSrc
mkdir -p ~/bin/x86_64
sed -i 's/HG_WARN_ERR = -DJK_WARN -Wall -Werror/HG_WARN_ERR = -DJK_WARN -Wall/g' inc/common.mk
make 'MACHTYPE = x86_64'
cp -puv ~/bin/x86_64/* $bin_folder/
# clean up
rm ~/bin/x86_64 -rf
cd $CWD

# install Jellyfish
# via http://www.vcru.wisc.edu/simonlab/bioinformatics/programs/install/jellyfish.htm
ver="1.1.11"
wget -N http://www.cbcb.umd.edu/software/jellyfish/jellyfish-$ver.tar.gz
tar -zxvf jellyfish-$ver.tar.gz
cd jellyfish-$ver
./configure --prefix=$install_folder
make
sudo make install
cd $CWD


# install amos pipeline
# http://www.vcru.wisc.edu/simonlab/bioinformatics/programs/install/amos.htm

sudo apt-get install libboost-graph-dev
sudo cpan XML::Parser Config::IniFiles Statistics::Descriptive DBI
git clone git://git.code.sf.net/p/amos/code amos-code
cd amos-code
./bootstrap
./configure --prefix=$install_folder
make CXXFLAGS='-Wno-deprecated'
sudo make install
cd $CWD


# Downloading and installing the SRA Toolkit
# http://www.ncbi.nlm.nih.gov/Traces/sra/sra.cgi?view=toolkit_doc&f=std#s-3
wget "ftp://ftp-trace.ncbi.nlm.nih.gov/sra/sdk/current/sratoolkit.current-centos_linux64.tar.gz"
tar xvzf sratoolkit.current-centos_linux64.tar.gz
sudo mv sratoolkit.2.6.3-centos_linux64 /usr/local/
sudo ln -s /usr/local/sratoolkit.2.6.3-centos_linux64 /usr/local/sratoolkit

