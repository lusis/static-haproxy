#!/bin/bash
yum install -y wget bzip2 patch gcc gcc-c++
HAPROXY_MAJOR_VERSION=2.0 HAPROXY_MINOR_VERSION=0 PCRE_VERSION=8.43 OPENSSL_VERSION=1.0.2s ZLIB_VERSION=1.2.11 ./compile.sh 
