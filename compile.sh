USE_STATIC_PCRE=1
TARGET=linux2628
HAPROXY_VERSION="${HAPROXY_MAJOR_VERSION}.${HAPROXY_MINOR_VERSION}"
PCRE_TARBALL="pcre-${PCRE_VERSION}.tar.bz2"
OPENSSL_TARBALL="openssl-${OPENSSL_VERSION}.tar.gz"
ZLIB_TARBALL="zlib-${ZLIB_VERSION}.tar.gz"
HAPROXY_TARBALL="haproxy-${HAPROXY_VERSION}.tar.gz"
#GLIBC_TARBALL="glibc-${GLIBC_VERSION}.tar.gz"
rm -rf haproxy-*
rm -rf pcre-*
rm -rf openssl-*
rm -rf zlib-*
CWD=$(pwd)
# create a new file to set timestamp, we are not using touch since we need the filesystem to provide time (to handle remote FS)
rm .timestamp || true
cat "" > .timestamp
if [[ ! -d "${PCRE_TARBALL%.tar.bz2}" ]]; then
  wget "https://ftp.pcre.org/pub/pcre/${PCRE_TARBALL}"
  tar --no-same-owner --mtime=.timestamp -jxvf "${PCRE_TARBALL}" && rm -f "${PCRE_TARBALL}"
  find "${PCRE_TARBALL%.tar.bz2}" -print0 |xargs -0 touch -r .timestamp
fi
 
if [[ ! -d "${OPENSSL_TARBALL%.tar.gz}" ]]; then
  wget "http://www.openssl.org/source/${OPENSSL_TARBALL}"
  tar --no-same-owner --mtime=.timestamp -zxvf "${OPENSSL_TARBALL}" && rm -f "${OPENSSL_TARBALL}"
  find "${OPENSSL_TARBALL%.tar.gz}" -print0 |xargs -0 touch -r .timestamp
fi
 
if [[ ! -d "${ZLIB_TARBALL%.tar.gz}" ]]; then
  wget "http://zlib.net/${ZLIB_TARBALL}"
  tar --no-same-owner --mtime=.timestamp -zxvf "${ZLIB_TARBALL}" && rm -rf "${ZLIB_TARBALL}"
  find "${ZLIB_TARBALL%.tar.gz}" -print0 |xargs -0 touch -r .timestamp
fi
if [[ ! -d "${HAPROXY_TARBALL%.tar.gz}" ]]; then
  wget "http://www.haproxy.org/download/${HAPROXY_MAJOR_VERSION}/src/${HAPROXY_TARBALL}"
  tar --no-same-owner --mtime=.timestamp -zxvf "${HAPROXY_TARBALL}" && rm -rf "${HAPROXY_TARBALL}"
  find "${HAPROXY_TARBALL%.tar.gz}" -print0 |xargs -0 touch -r .timestamp
fi
#if [[ ! -d "${GLIBC_TARBALL%.tar.gz}" ]]; then
#  wget "http://ftp.download-by.net/gnu/gnu/libc/${GLIBC_TARBALL}"
#  tar --no-same-owner -mtime=.timestamp -zvzf "${GLIBC_TARBALL}" && rm -rf "${GLIBC_TARBALL}"
#  find "${GLIBC_TARBALL%.tar.gz}" -print0 |xargs -0 touch -r .timestamp
#fi
cd $CWD/openssl-${OPENSSL_VERSION}
SSLDIR=$CWD/opensslbin
mkdir -p $SSLDIR
./config --prefix=$SSLDIR no-shared no-ssl2
make && make install_sw
PCREDIR=$CWD/pcrebin
mkdir -p $PCREDIR
cd $CWD/pcre-${PCRE_VERSION}
CFLAGS='-O2 -Wall' ./configure --prefix=$PCREDIR --disable-shared
make && make install
ZLIBDIR=$CWD/zlibbin
mkdir -p $ZLIBDIR
cd $CWD/zlib-${ZLIB_VERSION}
./configure --static --prefix=$ZLIBDIR
make && make install
mkdir -p $CWD/bin
cd $CWD/haproxy-${HAPROXY_VERSION}
patch -p0 Makefile < $CWD/haproxy_makefile.patch
sed -ibak "s#PREFIX = /usr/local#PREFIX = $CWD/bin#g" Makefile
make TARGET=linux-glibc EXTRA_OBJS="contrib/prometheus-exporter/service-prometheus.o" USE_STATIC_PCRE=1 USE_ZLIB=1 USE_OPENSSL=1 ZLIB_LIB=$ZLIBDIR/lib ZLIB_INC=$ZLIBDIR/include SSL_INC=$SSLDIR/include SSL_LIB=$SSLDIR/lib ADDLIB=-ldl -lzlib PCREDIR=$PCREDIR 
make install
cd $CWD/bin
cp $CWD/zlib-${ZLIB_VERSION}/README ZLIB-LICENSE
cp $CWD/openssl-${OPENSSL_VERSION}/LICENSE OpenSSL-License
cp $CWD/pcre-${PCRE_VERSION}/LICENCE PCRE-LICENSE
cp $CWD/haproxy-${HAPROXY_VERSION}/LICENSE HAPROXY-LICENSE
cat << EOF > README
Statically linked haproxy for production use.
Linked against
   Zlib ${ZLIB_VERSION}
   OpenSSL ${OPENSSL_VERSION}
   Pcre ${PCRE_VERSION}
See http://github.com/lusis/static-haproxy for more info
EOF
tar czf $TRAVIS_BUILD_DIR/$PCK_NAME.tar.gz .
