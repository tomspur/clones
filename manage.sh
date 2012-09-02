#!/usr/bin/env bash
# Copyright (c) 2012 - Thomas Spura <thomas.spura@gmail.com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

##################################################
# macros for each kind of buildsystem
CFLAGS="-O2 -pipe -march=native -mtune=native"
# virtualenv.py --no-site-packages --never-download ~/venv/mpcd
# where to install the venv
VENV=~/venv
function configure () {
    echo "RUNNING VIRTUAL_ENV CONFIGURE"
    ./configure $@ --prefix=$VIRTUAL_ENV
}

##################################################

set -e

function usage {
    echo "Usage: `basename $0` cmd [file]"
    echo "    where cmd is one of:"
    echo "    * create_env $name"
    echo "        creates virtualenv \$name at $VENV/\$name"
    echo "    * clone \$repo_file"
    echo "        clones all repositories from \$repo_file"
    echo "    * pull \$folder_with_cloned_repos"
    echo "        pulls all new changes inside the given folder"
    echo "    * build \$repo_file"
    echo "        builds each repository from \$repo_file"
    echo "    * install \$repo_file"
    echo "        installs each repository from \$repo_file into $VENV/\$name"
    echo "    * build \$repo_file"
    echo "        builds and installs each repository from \$repo_file directly"
    echo "        directly in one step into $VENV/\$name"
    exit 11
}

if [ $# -ne 2 ]
then
    usage
fi

function assert_venv {
    if [ "x$VIRTUAL_ENV" = 'x' ]; then
        echo "Not inside of virtualenv. Aborting..."
        exit 7
    fi
}

function clone {
    echo "Cloning $1 repository into $2"
    if ! test -d $4; then
        mkdir -p $4
    fi
    cd $4
    if ! test -d $2; then
        case $1 in
            git )
                git clone $3 $2
                ;;
            hg )
                hg clone $3 $2
                ;;
            * )
                echo "What kind of repo is $1 ?"
                ;;
        esac
    else
        echo "$2 already exists. Skipping..."
    fi
    cd ..
}

function pull {
    echo "Pulling inside of $PWD"
    if test -d .git; then
        git pull
    fi
    if test -d .hg; then
        hg pull && hg update
    fi
}

function build {
    venv=$1
    scm=$2
    pkg=$3
    url=$4
    assert_venv
    cd $3
    echo "Building $3 inside of $PWD"
    if test -e ../$pkg.BUILD; then
        echo "Running custom build script from ../$pkg.BUILD"
        ../$pkg.BUILD
        cd ..
        return
    fi
    case $(ls setup.py autogen.sh configure 2>/dev/null) in
        *setup.py* )
            CFLAGS=$CFLAGS python setup.py build
            ;;
        *autogen.sh* )
            CFLAGS=$CFLAGS ./autogen.sh
            CFLAGS=$CFLAGS configure
            make -j$(getconf _NPROCESSORS_ONLN) VERBOSE=1
            ;;
        *configure* )
            CFLAGS=$CFLAGS configure
            make -j$(getconf _NPROCESSORS_ONLN) VERBOSE=1
            ;;
        * )
            echo "Buildsystem not recognized. Aborting..."
            exit 9
    esac
    cd ..
}

function install {
    venv=$1
    scm=$2
    folder=$3
    url=$4
    assert_venv
    cd $3
    echo "Installing inside of $PWD"
    if test -e ../$pkg.INSTALL; then
        echo "Running custom build script from ../$pkg.INSTALL"
        ../$pkg.INSTALL
        return
    fi
    case $(ls setup.py autogen.sh configure 2>/dev/null) in
        *setup.py* )
            python setup.py install
            ;;
        *configure* )
            # includes autogen.sh case from build
            make install
            ;;
        * )
            echo "Buildsystem not recognized. Aborting..."
            exit 9
    esac
    cd ..
    assert_venv
}

function create {
    # creates venv
    # TODO if existent remove first?
    if test -d $VENV/$1; then
        echo "virtualenv $1 already exists. Aborting..."
        exit 8
    fi
    if test -d ./virtualenv/virtualenv/; then
        ./virtualenv/virtualenv/virtualenv.py \
            --never-download \
            --no-site-packages \
            $VENV/$1
    else
        echo "Did you checkout virtualenv repo?"
        echo "Are you in the root of clones.git repository?"
        echo "Aborting..."
        exit 9
    fi
}

##################################################

case $1 in
    clone )
        cat $2 | while read LINE ; do
            env=$(echo ${2} | sed 's/.repo//')
            clone $LINE $env
        done
        ;;
    pull )
        env=$(echo ${2} | sed 's/.repo//')
        cd $env
            for folder in * ; do
                cd $folder
                    pull
                cd ..
            done
        cd ..
        ;;
    build )
        env=$(echo ${2} | sed 's/.repo//')
        cd $env
            cat ../$2 | while read LINE ; do
                build $env $LINE
            done
        cd ..
        ;;
    install )
        env=$(echo ${2} | sed 's/.repo//')
        cd $env
            cat ../$2 | while read LINE ; do
                install $env $LINE
            done
        cd ..
        ;;
    binstall )
        env=$(echo ${2} | sed 's/.repo//')
        cd $env
            cat ../$2 | while read LINE ; do
                build $env $LINE
                install $env $LINE
            done
        cd ..
        ;;
    create_env )
        create $2
        ;;
    * )
        usage
        ;;
esac
