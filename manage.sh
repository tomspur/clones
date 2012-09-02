#!/usr/bin/env bash
# Copyright (c) 2012 - Thomas Spura <tomspur@gmail.com>

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

if [ $# -ne 2 ]
then
    echo "Usage: `basename $0` cmd [file]"
    echo "    where cmd is one of:"
    echo "    * clone \$repo_file"
    echo "        clones all repositories from \$repo_file"
    echo "    * pull \$folder_with_cloned_repos"
    echo "        pulls all new changes inside the given folder"
    echo "    * create_env $name"
    echo "        creates virtualenv \$name at $VENV/\$name"
    exit 11
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
    folder=$3
    url=$4
    assert_venv
    cd $3
    echo "Building $3 inside of $PWD"
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
        cd $2
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
esac
