#!/usr/bin/env bash
# Copyright (c) 2012 - Thomas Spura <tomspur@gmail.com>

##################################################
# macros for each kind of buildsystem
CFLAGS="-O2 -pipe -march=native -mtune=native"
# virtualenv.py --no-site-packages --never-download ~/venv/mpcd
function configure () {
    echo "RUNNING CONFIGURE FROM BASHRC"
    ./configure $@ --prefix=$VIRTUAL_ENV
}

##################################################


if [ $# -ne 2 ]
then
    echo "Usage: `basename $0` clone file"
    exit 11
fi

function assert_venv {
    if [ "x$VIRTUAL_ENV" = 'x' ]; then
        echo "Not inside of virtualenv. Aborting..."
        exit 7
    fi
}

function clone {
    echo "Cloning $1 into $2"
    if ! test -d $2; then
        mkdir -p $2
    fi
    case $1 in
        git://* )
            cd $2
            git clone $1
            cd ..
            ;;
        *bitbucket* )
            cd $2
            hg clone $1
            cd ..
            ;;
        * )
            echo "What kind of repo is $1 ?"
            ;;
    esac
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
    assert_venv
    echo "Building inside of $PWD"
    # detect how and search deps
}

function install {
    assert_venv
    echo "Installing inside of $PWD"
    # detect how, or directly with build?
}

function create {
    # creates venv
    # TODO if existent remove first?
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
        cd $2
            for folder in * ; do
                cd $folder
                    build
                cd ..
            done
        cd ..
        ;;
    install )
        cd $2
            for folder in * ; do
                cd $folder
                    build
                cd ..
            done
        cd ..
        ;;
    env )
        ./virtualenv/virtualenv/virtualenv.py --never-download --no-site-packages ~/venv/$2
        ;;
esac
