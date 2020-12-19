#!/bin/bash

cd /var/www || exit

vnstati -i ens3 -o d.png -d
vnstati -i ens3 -o hs.png -vs
