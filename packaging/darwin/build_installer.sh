#!/bin/bash
set -ev

# Build requisites
PATH=~/Library/Python/2.7/bin:$PATH

BUILD_DIR=/tmp/build
INSTALL_DIR=/tmp/installation
DEST_VENV=/usr/local/sd-agent/
DARWIN_SCRIPTS=packaging/darwin

source ${DARWIN_SCRIPTS}/darwin_version.sh
PKG_NAME="Server Density Agent Installer ${AGENT_VERSION}.pkg"

VENV_PYTHON_CMD="${BUILD_DIR}/bin/python"
VENV_PIP_CMD="${BUILD_DIR}/bin/pip"

# Prepare virtual environment
mkdir -p ${BUILD_DIR}
curl -LO https://pypi.python.org/packages/source/v/virtualenv/virtualenv-13.1.2.tar.gz
tar xzf virtualenv-13.1.2.tar.gz
python virtualenv-13.1.2/virtualenv.py ${BUILD_DIR}

$VENV_PIP_CMD install -r requirements.txt
PIP_COMMAND=${VENV_PIP_CMD} ./utils/pip-allow-failures.sh requirements-opt.txt
${VENV_PYTHON_CMD} setup.py build
${VENV_PYTHON_CMD} setup.py install

# Fix venv activate paths.
sed -i ".bak" "s|^VIRTUAL_ENV=.*|VIRTUAL_ENV=${DEST_VENV}|" ${BUILD_DIR}/bin/activate
sed -i "'.bak'" "s|^setenv VIRTUAL_ENV.*|setenv VIRTUAL_ENV ${DEST_VENV}|" ${BUILD_DIR}/bin/activate.csh
sed -i "'.bak'" "s|^set -gx VIRTUAL_ENV.*|set -gx VIRTUAL_ENV ${DEST_VENV}|" ${BUILD_DIR}/bin/activate.fish

# Fix venv shebangs
grep -l -r -e '^#!.*bin/\(env \)\?\(python\|pypy\|ipy\|jython\)' ${BUILD_DIR}/bin | xargs sed -i ".bak" 's|^#!.*bin/\(env \)\?.*|#!$(DEST_VENV)/bin/python|'
sed -i ".bak" 's|^#!.*bin/\(env \)\?.*|#!$(DEST_VENV)/bin/python|' agent.py

# Remove backup files
rm -f ${BUILD_DIR}/bin/*.bak

# Copy the files to the install dir.

# Copy main agent code.
mkdir -p ${INSTALL_DIR}/sd-agent
mkdir -p ${INSTALL_DIR}/sd-agent/lib/python2.7/site-packages
cp agent.py \
aggregator.py \
config.py \
daemon.py \
sdagent.py \
emitter.py \
graphite.py \
modules.py \
sd-cert.pem \
transaction.py \
util.py ${INSTALL_DIR}/sd-agent

cp -a ${BUILD_DIR}/.Python ${INSTALL_DIR}/sd-agent/
cp -a ${BUILD_DIR}/bin ${INSTALL_DIR}/sd-agent/
cp -a ${BUILD_DIR}/include ${INSTALL_DIR}/sd-agent/
cp -a ${BUILD_DIR}/lib/python2.7/*.py ${INSTALL_DIR}/sd-agent/lib/python2.7
cp -a ${BUILD_DIR}/lib/python2.7/distutils ${INSTALL_DIR}/sd-agent/lib/python2.7
cp -a ${BUILD_DIR}/lib/python2.7/encodings ${INSTALL_DIR}/sd-agent/lib/python2.7
cp -a ${BUILD_DIR}/lib/python2.7/lib-dynload ${INSTALL_DIR}/sd-agent/lib/python2.7
cp -a ${BUILD_DIR}/lib/python2.7/no-global-site-packages.txt ${INSTALL_DIR}/sd-agent/lib/python2.7
cp -a ${BUILD_DIR}/lib/python2.7/orig-prefix.txt ${INSTALL_DIR}/sd-agent/lib/python2.7
cp -a ${BUILD_DIR}/lib/python2.7/site-packages/backports* ${INSTALL_DIR}/sd-agent/lib/python2.7/site-packages
cp -a ${BUILD_DIR}/lib/python2.7/site-packages/boto* ${INSTALL_DIR}/sd-agent/lib/python2.7/site-packages
cp -a ${BUILD_DIR}/lib/python2.7/site-packages/*consul* ${INSTALL_DIR}/sd-agent/lib/python2.7/site-packages
cp -a ${BUILD_DIR}/lib/python2.7/site-packages/dns* ${INSTALL_DIR}/sd-agent/lib/python2.7/site-packages
cp -a ${BUILD_DIR}/lib/python2.7/site-packages/docker* ${INSTALL_DIR}/sd-agent/lib/python2.7/site-packages
cp -a ${BUILD_DIR}/lib/python2.7/site-packages/easy-install* ${INSTALL_DIR}/sd-agent/lib/python2.7/site-packages
cp -a ${BUILD_DIR}/lib/python2.7/site-packages/*etcd* ${INSTALL_DIR}/sd-agent/lib/python2.7/site-packages
cp -a ${BUILD_DIR}/lib/python2.7/site-packages/ipaddress.py* ${INSTALL_DIR}/sd-agent/lib/python2.7/site-packages
cp -a ${BUILD_DIR}/lib/python2.7/site-packages/_markerlib ${INSTALL_DIR}/sd-agent/lib/python2.7/site-packages
cp -a ${BUILD_DIR}/lib/python2.7/site-packages/meld3* ${INSTALL_DIR}/sd-agent/lib/python2.7/site-packages
cp -a ${BUILD_DIR}/lib/python2.7/site-packages/ntplib* ${INSTALL_DIR}/sd-agent/lib/python2.7/site-packages
cp -a ${BUILD_DIR}/lib/python2.7/site-packages/pip* ${INSTALL_DIR}/sd-agent/lib/python2.7/site-packages
cp -a ${BUILD_DIR}/lib/python2.7/site-packages/pkg_resources ${INSTALL_DIR}/sd-agent/lib/python2.7/site-packages
cp -a ${BUILD_DIR}/lib/python2.7/site-packages/psutil* ${INSTALL_DIR}/sd-agent/lib/python2.7/site-packages
cp -a ${BUILD_DIR}/lib/python2.7/site-packages/pycurl* ${INSTALL_DIR}/sd-agent/lib/python2.7/site-packages
cp -a ${BUILD_DIR}/lib/python2.7/site-packages/PyYAML* ${INSTALL_DIR}/sd-agent/lib/python2.7/site-packages
cp -a ${BUILD_DIR}/lib/python2.7/site-packages/requests* ${INSTALL_DIR}/sd-agent/lib/python2.7/site-packages
cp -a ${BUILD_DIR}/lib/python2.7/site-packages/*scandir* ${INSTALL_DIR}/sd-agent/lib/python2.7/site-packages
cp -a ${BUILD_DIR}/lib/python2.7/site-packages/sd_agent* ${INSTALL_DIR}/sd-agent/lib/python2.7/site-packages
cp -a ${BUILD_DIR}/lib/python2.7/site-packages/setuptools* ${INSTALL_DIR}/sd-agent/lib/python2.7/site-packages
cp -a ${BUILD_DIR}/lib/python2.7/site-packages/simplejson* ${INSTALL_DIR}/sd-agent/lib/python2.7/site-packages
cp -a ${BUILD_DIR}/lib/python2.7/site-packages/six.py ${INSTALL_DIR}/sd-agent/lib/python2.7/site-packages
cp -a ${BUILD_DIR}/lib/python2.7/site-packages/six-*-info ${INSTALL_DIR}/sd-agent/lib/python2.7/site-packages
cp -a ${BUILD_DIR}/lib/python2.7/site-packages/tornado* ${INSTALL_DIR}/sd-agent/lib/python2.7/site-packages
cp -a ${BUILD_DIR}/lib/python2.7/site-packages/uptime* ${INSTALL_DIR}/sd-agent/lib/python2.7/site-packages
cp -a ${BUILD_DIR}/lib/python2.7/site-packages/urllib3* ${INSTALL_DIR}/sd-agent/lib/python2.7/site-packages
cp -a ${BUILD_DIR}/lib/python2.7/site-packages/websocket* ${INSTALL_DIR}/sd-agent/lib/python2.7/site-packages
cp -a ${BUILD_DIR}/lib/python2.7/site-packages/yaml ${INSTALL_DIR}/sd-agent/lib/python2.7/site-packages

# Copy default plugins.
mkdir -p ${INSTALL_DIR}/sd-agent/checks.d
cp checks.d/disk.py \
checks.d/sd.py \
checks.d/sd_cpu_stats.py \
checks.d/network.py ${INSTALL_DIR}/sd-agent/checks.d

# Copy default config files.
mkdir -p ${INSTALL_DIR}/etc/sd-agent
mkdir -p ${INSTALL_DIR}/etc/sd-agent/conf.d
cp config.cfg.example ${INSTALL_DIR}/etc/sd-agent/config.cfg
cp plugins.cfg.example ${INSTALL_DIR}/etc/sd-agent/plugins.cfg
cp conf.d/disk.yaml.default \
conf.d/sd.yaml.default \
conf.d/sd_cpu_stats.yaml.default \
conf.d/network.yaml.default ${INSTALL_DIR}/etc/sd-agent/conf.d

# Copy startup item
cp ${DARWIN_SCRIPTS}/com.serverdensity.agent.plist ${INSTALL_DIR}/sd-agent

# Supported plugins.

# Apache
cp checks.d/apache.py ${INSTALL_DIR}/sd-agent/checks.d
cp conf.d/apache.yaml.example ${INSTALL_DIR}/etc/sd-agent/conf.d

# Consul
cp checks.d/consul.py ${INSTALL_DIR}/sd-agent/checks.d
cp conf.d/consul.yaml.example ${INSTALL_DIR}/etc/sd-agent/conf.d

# CouchBase
cp checks.d/couchbase.py ${INSTALL_DIR}/sd-agent/checks.d
cp conf.d/couchbase.yaml.example ${INSTALL_DIR}/etc/sd-agent/conf.d

# CouchDB
cp checks.d/couch.py ${INSTALL_DIR}/sd-agent/checks.d
cp conf.d/couch.yaml.example ${INSTALL_DIR}/etc/sd-agent/conf.d

# Directory
cp checks.d/directory.py ${INSTALL_DIR}/sd-agent/checks.d
cp conf.d/directory.yaml.example ${INSTALL_DIR}/etc/sd-agent/conf.d

# Docker
cp checks.d/docker.py ${INSTALL_DIR}/sd-agent/checks.d
cp conf.d/docker.yaml.example ${INSTALL_DIR}/etc/sd-agent/conf.d

# Elastic Search
cp checks.d/elastic.py ${INSTALL_DIR}/sd-agent/checks.d
cp conf.d/elastic.yaml.example ${INSTALL_DIR}/etc/sd-agent/conf.d

# HDFS
cp checks.d/hdfs_datanode.py ${INSTALL_DIR}/sd-agent/checks.d
cp checks.d/hdfs_namenode.py ${INSTALL_DIR}/sd-agent/checks.d
cp conf.d/hdfs_datanode.yaml.example ${INSTALL_DIR}/etc/sd-agent/conf.d
cp conf.d/hdfs_namenode.yaml.example ${INSTALL_DIR}/etc/sd-agent/conf.d

# HAProxy
cp checks.d/haproxy.py ${INSTALL_DIR}/sd-agent/checks.d
cp conf.d/haproxy.yaml.example ${INSTALL_DIR}/etc/sd-agent/conf.d

# Memcache
cp checks.d/mcache.py ${INSTALL_DIR}/sd-agent/checks.d
cp conf.d/mcache.yaml.example ${INSTALL_DIR}/etc/sd-agent/conf.d
cp -a ${BUILD_DIR}/lib/python2.7/site-packages/memcache.py ${INSTALL_DIR}/sd-agent/lib/python2.7/site-packages

# MySQL
cp checks.d/mysql.py ${INSTALL_DIR}/sd-agent/checks.d
cp conf.d/mysql.yaml.example ${INSTALL_DIR}/etc/sd-agent/conf.d
cp -a ${BUILD_DIR}/lib/python2.7/site-packages/pymysql ${INSTALL_DIR}/sd-agent/lib/python2.7/site-packages
cp -a ${BUILD_DIR}/lib/python2.7/site-packages/PyMySQL* ${INSTALL_DIR}/sd-agent/lib/python2.7/site-packages

# Nginx
cp checks.d/nginx.py ${INSTALL_DIR}/sd-agent/checks.d
cp conf.d/nginx.yaml.example ${INSTALL_DIR}/etc/sd-agent/conf.d

# ntp
cp checks.d/ntp.py ${INSTALL_DIR}/sd-agent/checks.d
cp conf.d/ntp.yaml.default ${INSTALL_DIR}/etc/sd-agent/conf.d

# phpfpm
cp checks.d/php_fpm.py ${INSTALL_DIR}/sd-agent/checks.d
cp conf.d/php_fpm.yaml.example ${INSTALL_DIR}/etc/sd-agent/conf.d

# postfix
cp checks.d/postfix.py ${INSTALL_DIR}/sd-agent/checks.d
cp conf.d/postfix.yaml.example ${INSTALL_DIR}/etc/sd-agent/conf.d

# PostgreSQL
cp checks.d/postgres.py ${INSTALL_DIR}/sd-agent/checks.d
cp conf.d/postgres.yaml.example ${INSTALL_DIR}/etc/sd-agent/conf.d
cp -a ${BUILD_DIR}/lib/python2.7/site-packages/pg8000 ${INSTALL_DIR}/sd-agent/lib/python2.7/site-packages

# RabbitMQ
cp checks.d/rabbitmq.py ${INSTALL_DIR}/sd-agent/checks.d
cp conf.d/rabbitmq.yaml.example ${INSTALL_DIR}/etc/sd-agent/conf.d

# Redis
cp checks.d/redisdb.py ${INSTALL_DIR}/sd-agent/checks.d
cp conf.d/redisdb.yaml.example ${INSTALL_DIR}/etc/sd-agent/conf.d
cp -a ${BUILD_DIR}/lib/python2.7/site-packages/redis ${INSTALL_DIR}/sd-agent/lib/python2.7/site-packages

# Riak
cp checks.d/riak.py ${INSTALL_DIR}/sd-agent/checks.d
cp checks.d/riakcs.py ${INSTALL_DIR}/sd-agent/checks.d
cp conf.d/riak.yaml.example ${INSTALL_DIR}/etc/sd-agent/conf.d
cp conf.d/riakcs.yaml.example ${INSTALL_DIR}/etc/sd-agent/conf.d

# Varnish
cp checks.d/varnish.py ${INSTALL_DIR}/sd-agent/checks.d
cp conf.d/varnish.yaml.example ${INSTALL_DIR}/etc/sd-agent/conf.d

# Package it up
pkgbuild --identifier com.serverdensity.agent-service \
--version ${AGENT_VERSION} \
--install-location "/usr/local/" \
--scripts ${DARWIN_SCRIPTS}/scripts \
--ownership recommended \
--root ${INSTALL_DIR} \
--component-plist ${DARWIN_SCRIPTS}/AgentComponents.plist \
"Server Density Agent Service.pkg"

# TODO: Package a preference pane as a separate component
mkdir -p diskimage

if [ ! -z "${DARWIN_INSTALLER_CN}" ]; then

    # Retrieve signing key from Travis environment and add it to a new default keychain
    echo ${DARWIN_INSTALLER_KEY} | base64 -D -o ServerDensity.p12
    KEYCHAIN_NAME=agent.keychain
    security create-keychain -p travis ${KEYCHAIN_NAME}
    security default-keychain -s ${KEYCHAIN_NAME}
    security unlock-keychain -p travis
    security set-keychain-settings -t 3600 -u
    security import ServerDensity.p12 -f pkcs12 -P "" -k ${KEYCHAIN_NAME} -T /usr/bin/productbuild
    # this may help when debugging, lists the known identities:
    # security find-identity

    productbuild --distribution ${DARWIN_SCRIPTS}/distribution.xml \
        --identifier com.serverdensity.agent \
        --resources ${DARWIN_SCRIPTS}/Resources \
        --sign "${DARWIN_INSTALLER_CN}" \
        diskimage/"${PKG_NAME}"

    # Trust, but verify
    spctl --assess --type install diskimage/"${PKG_NAME}"
else
    echo "Signing disabled..."
    productbuild --distribution ${DARWIN_SCRIPTS}/distribution.xml \
        --identifier com.serverdensity.agent \
        --resources ${DARWIN_SCRIPTS}/Resources \
        diskimage/"${PKG_NAME}"
fi

# Add the icon
${DARWIN_SCRIPTS}/scripts/setIcon.py ${DARWIN_SCRIPTS}/Resources/sd-agent-installer.icns diskimage/"${PKG_NAME}"

# Package the disk image
# This may fail sometimes due to a "Resource busy" error, in that case re-running the job usually fixes it
hdiutil create -srcfolder diskimage -volname "Agent Installer" "sd-agent-${AGENT_VERSION}.dmg"
