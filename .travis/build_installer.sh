#!/bin/bash
set -ev

if [ "${TRAVIS_OS_NAME}" == "osx" ]; then

    # Only run on default flavor.
    ./packaging/darwin/build_installer.sh

else

    bundle install
    bundle package
    # Needed if no cache exists
    mkdir -p $INTEGRATIONS_DIR
    ls -al $INTEGRATIONS_DIR
    rm -rf /home/travis/virtualenv/python$TRAVIS_PYTHON_VERSION.9/lib/python$TRAVIS_PYTHON_VERSION/site-packages/pip-6.0.7.dist-info
    rm -rf /home/travis/virtualenv/python$TRAVIS_PYTHON_VERSION.9/lib/python$TRAVIS_PYTHON_VERSION/site-packages/setuptools-12.0.5.dist-info
    rake ci:run
    ls -al $INTEGRATIONS_DIR

fi
