#!/bin/bash

set -e

fname=$1

zip -er "$fname.zip" "$fname/"
