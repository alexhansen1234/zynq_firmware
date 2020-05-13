#!/bin/bash
export CROSS_COMPILE=arm-linux-gnueabihf-
export VIVADO_SETTINGS=$HOME/opt/Vivado/2019.2/settings64.sh
export VITIS_SETTINGS=$HOME/opt/Vitis/2019.2/settings64.sh
source $VIVADO_SETTINGS
source $VITIS_SETTINGS
export PATH=/home/alex/opt/Vitis/2019.2/gnu/aarch32/lin/gcc-arm-linux-gnueabi/bin:$PATH
