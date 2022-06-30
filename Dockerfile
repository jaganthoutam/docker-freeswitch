FROM centos:7

ENV \
    LANGUAGE="en_US.UTF-8" \
    LANG="en_US.UTF-8" \
    LC_ALL=C \
    SOFIA_SIP_VERSION=v1.13.7 \
    SPANDSP_VERSION=e59ca8f \
    FS_VERSION=v1.10.7

RUN \
    yum install -y epel-release which autoconf automake libtool make gcc-c++ file wget && \
    yum install -y zlib-devel libjpeg-devel sqlite-devel libcurl-devel pcre-devel libtiff-devel speex-devel libedit-devel openssl-devel && \
    yum install libvorbis libvorbis-devel vorbis-tools libogg libogg-devel -y &&\
    yum install mpg123-devel mpg123-libs libshout-devel -y &&\
    wget -q https://raw.githubusercontent.com/jaganthoutam/docker-freeswitch/main/okay.repo -O /etc/yum.repos.d/okay.repo &&\
    yum update -y &&\
    yum install gsm gsm-devel gsm-tools -y &&\
    rpm -Uvh https://download1.rpmfusion.org/free/el/rpmfusion-free-release-7.noarch.rpm &&\
    yum install ffmpeg ffmpeg-devel -y &&\
    yum install curl curl-devel libidn-devel -y &&\
    yum install gcc ncurses-devel make gcc-c++ zlib-devel libtool bison-devel bison libpqxx-devel \
        openssl-devel bzip2-devel wget newt-devel subversion flex gtk2-devel bzip2 patch \
        libjpeg-devel yasm-devel libsndfile-devel net-tools git perl-ExtUtils-Embed libatomic -y &&\
    yum install unixODBC unixODBC-devel libtool-ltdl-devel -y &&\
    yum install sqlite sqlite-devel -y &&\
    yum install libuuid libuuid-devel uuid uuid-devel -y &&\
    yum install speex speex-devel wavpack wavpack-devel lame lame-devel -y

RUN \
    cd /usr/src &&\
    git clone https://github.com/festvox/flite.git &&\
    cd flite/ &&\
    ./configure --enable-shared --with-audio=none --prefix=/usr &&\
    make &&\
    make get_voices &&\
    make install
RUN \
   cd /usr/src &&\
   wget https://campus.voztovoice.org/FreeSWITCH/libmad-0.15.1b.tar.gz &&\
   tar -xf libmad-0.15.1b.tar.gz  &&\
   cd libmad-0.15.1b &&\
   ./configure --prefix=/usr --libdir=/usr/lib64

RUN wget -q https://raw.githubusercontent.com/jaganthoutam/docker-freeswitch/main/libmad/Makefile -O /usr/src/libmad-0.15.1b/Makefile &&\
   cd /usr/src/libmad-0.15.1b &&\
   make &&\
   make install


RUN \
    cd /usr/src &&\
    wget https://archive.mozilla.org/pub/opus/opus-1.1.1.tar.gz &&\
    tar -xf opus-1.1.1.tar.gz &&\
    cd opus-1.1.1 &&\
    ./configure --prefix=/usr --libdir=/usr/lib64 &&\
    make &&\
    make install &&\
    yum install opus-tools -y

RUN \
    cd /usr/src &&\
    wget https://campus.voztovoice.org/FreeSWITCH/sox-14.4.2.tar.gz &&\
    tar -xf sox-14.4.2.tar.gz &&\
    cd sox-14.4.2 &&\
    ./configure --prefix=/usr --libdir=/usr/lib64 &&\
    make && make install &&\
    yum install libtiff libtiff-devel libxml2 libxml2-devel -y &&\
    yum --enablerepo=okay install spandsp spandsp-apidoc spandsp-devel -y &&\
    yum install gnutls gnutls-devel gnutls-utils -y

RUN rpm -ivh https://repo.zabbix.com/zabbix/3.0/rhel/7/x86_64/zabbix-release-3.0-1.el7.noarch.rpm
RUN yum install iksemel iksemel-devel iksemel-utils -y
RUN yum install compat-openldap openldap openldap-clients openldap-devel openldap-servers -y
RUN yum install radiusclient-ng radiusclient-ng-devel radiusclient-ng-utils -y
RUN yum install lua lua-devel -y
RUN yum install memcached memcached-devel libmemcached libmemcached-devel -y
RUN yum --enablerepo=okay install libsrtp libsrtp-devel -y
RUN yum install jansson jansson-devel -y
RUN yum install portaudio portaudio-devel python-devel perl-devel erlang ldns-devel libedit-devel -y



ADD https://github.com/freeswitch/sofia-sip/archive/${SOFIA_SIP_VERSION}.tar.gz /usr/src/sofia-sip.tar.gz
ADD https://github.com/freeswitch/spandsp/archive/${SPANDSP_VERSION}.tar.gz /usr/src/spandsp.tar.gz
ADD https://github.com/signalwire/freeswitch/archive/${FS_VERSION}.tar.gz /usr/src/freeswitch.tar.gz

RUN \
    mkdir -p /usr/src/{freeswitch,sofia-sip,spandsp} && \
    tar -xf /usr/src/freeswitch.tar.gz -C /usr/src/freeswitch --strip-components=1 && \
    tar -xf /usr/src/sofia-sip.tar.gz -C /usr/src/sofia-sip --strip-components=1 && \
    tar -xf /usr/src/spandsp.tar.gz -C /usr/src/spandsp --strip-components=1 && \
    rm /usr/src/{freeswitch,sofia-sip,spandsp}.tar.gz

RUN \
    cd /usr/src/sofia-sip && \
    ./bootstrap.sh -j && \
    ./configure --prefix=/usr --libdir=/usr/lib64 --enable-static=no && \
    make install &&\
    rpm -Uvh https://campus.voztovoice.org/FreeSWITCH/libks-1.7.0-16.el7.centos.rpm


RUN \
    cd /usr/src/spandsp && \
    ./bootstrap.sh -j && \
    ./configure --prefix=/usr --libdir=/usr/lib64 --enable-static=no


WORKDIR /usr/src/freeswitch

RUN \
    ./bootstrap.sh -j && \
    wget -q https://raw.githubusercontent.com/jaganthoutam/docker-freeswitch/main/modules.conf -O modules.conf && \
    ./configure -C --enable-portable-binary \
    --prefix=/usr --localstatedir=/var --sysconfdir=/etc \
    --with-gnu-ld --with-python --with-erlang --with-openssl \
    --enable-core-odbc-support --enable-zrtp \
    --enable-core-pgsql-support \
    --enable-static-v8 --disable-parallel-build-v8

RUN \
    yum install -y yasm && \
    make &&\
    make install &&\
    make cd-sounds-install &&\
    make cd-moh-install

RUN wget -q https://raw.githubusercontent.com/jaganthoutam/docker-freeswitch/main/autoconfig-modules.conf -O /etc/freeswitch/autoload_configs/modules.conf.xml

RUN \
    make cd-sounds cd-moh && \
    make install-binPROGRAMS && \
    make install-library_includeHEADERS install-library_includetestHEADERS install-pkgconfigDATA

RUN \
    cd src/mod/applications/mod_commands && \
    make install

RUN \
    cd src/mod/applications/mod_dptools && \
    make install

CMD ["/bin/bash"]
