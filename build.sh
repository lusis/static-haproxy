#!/bin/bash
yum install -y wget bzip2 patch gcc gcc-c++
HAPROXY_MAJOR_VERSION=1.9 HAPROXY_MINOR_VERSION=5 PCRE_VERSION=8.43 OPENSSL_VERSION=1.0.2r ZLIB_VERSION=1.2.11 ./compile.sh 
