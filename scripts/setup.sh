#!/usr/bin/env bash

git clone git@github.com:pedroagribeiro/dotfiles.git ~/.dotfiles
git clone git@github.com:pedroagribeiro/spells.git ~/.spells

cd ~/.dotfiles
make install
