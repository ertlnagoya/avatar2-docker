FROM ubuntu:16.04

# Sttings for Japan
RUN sed -i'~' -E "s@http://(..\.)?(archive|security)\.ubuntu\.com/ubuntu@http://ftp.jaist.ac.jp/pub/Linux/ubuntu@g" /etc/apt/sources.list

### basic install
RUN apt update
#### software-properties-common inclues `add-apt-repository`
RUN apt install -y software-properties-common 
RUN add-apt-repository -y ppa:team-gcc-arm-embedded/ppa
RUN apt update
RUN apt install -y git make binutils-dev \
    gettext flex bison pkg-config wget curl \
    libglib2.0-dev nasm liblua5.1-0-dev libsigc++-2.0-dev \
    texinfo gcc-arm-embedded expat libexpat1-dev python2.7-dev \
    g++ build-essential python3 python3-pip \
    libexpat1-dev sudo libc++-dev libc++1 \
    libiberty-dev clang-3.6 libc6-dev-i386 subversion libtool \
    pkg-config autoconf automake libusb-1.0 usbutils man less telnet vim nano
#   gdb-arm-none-eabi
# RUN pip3 install --upgrade pip

### install usefull tools
RUN apt install -y vim silversearcher-ag bash-completion lsof 
RUN apt install -y mlocate && updatedb

### lua
RUN apt install -y lua5.1 luarocks
RUN git clone https://github.com/ldrumm/chronos && cd chronos && luarocks make rockspecs/chronos-0.2-1.rockspec && \
    luarocks build luasocket

### change working directory and prepare to install avatar2
WORKDIR /home/avatar/projects
# RUN git config --global user.name "Eurecom.S3"
RUN mkdir -p /home/avatar/projects

### tmux
RUN apt install -y tmux
### additional installation for tmux 
### (1) install tmux-plugins/tpm
### (2) install tmux-plugins/tmux-resurrect
RUN git clone https://github.com/tmux-plugins/tpm /home/avatar/.tmux/plugins/tpm && \
    echo "\n\
# List of plugins\n\
set -g @plugin 'tmux-plugins/tpm'\n\
set -g @plugin 'tmux-plugins/tmux-sensible'\n\
\n\
# Other examples:\n\
# set -g @plugin 'github_username/plugin_name'\n\
# set -g @plugin 'git@github.com/user/plugin'\n\
# set -g @plugin 'git@bitbucket.com/user/plugin'\n\
\n\
# Initialize TMUX plugin manager (keep this line at the very bottom of tmux.conf)\n\
run '~/.tmux/plugins/tpm/tpm'\n\
\n\
set -g @plugin 'tmux-plugins/tmux-resurrect'\n\
# for vim\n\
set -g @resurrect-strategy-vim 'session'\n\
" >> /home/avatar/.tmux.conf    

### Avatar2
RUN git clone https://github.com/avatartwo/avatar2.git
RUN cd avatar2 && pip3 install .
RUN apt install -y libpixman-1-dev
# RUN cd avatar2/targets && ./build_*.sh
#### from targets/build_panda.sh
RUN echo "deb-src http://archive.ubuntu.com/ubuntu/ xenial-security main restricted" >> /etc/apt/sources.list && \
    apt-get update && \
    apt-get build-dep -y qemu && \
    apt-get -y install protobuf-compiler protobuf-c-compiler \
        libprotobuf-c0-dev libprotoc-dev libelf-dev libc++-dev && \
    add-apt-repository -y ppa:phulin/panda && \
    apt-get update && \
    apt-get -y install libcapstone-dev libdwarf-dev python-pycparser \
        libwiretap-dev libwireshark-dev
RUN cd avatar2/targets && cd `dirname "$BASH_SOURCE"`/src/ && \
    git submodule update --init avatar-panda
RUN cd avatar2/targets/src && cd avatar-panda && \
    git submodule update --init dtc
RUN mkdir -p avatar2/targets/build/panda/panda && \
    cd avatar2/targets/build/panda/panda && \
    ../../../src/avatar-panda/configure --disable-sdl --target-list=arm-softmmu && \
    make -j4

### Avatar2 examples
RUN git clone https://github.com/avatartwo/avatar2-examples.git

### OpenOCD
RUN apt install -y libhidapi-dev
RUN git clone https://github.com/ntfreak/openocd.git
RUN cd /home/avatar/projects/openocd;./bootstrap;./configure --enable-jlink --enable-maintainer-mode --enable-ftdi --enable-cmsis-dap --enable-hidapi-libusb; make -j6; make install

### add user avatar
RUN useradd -ms /bin/bash avatar
RUN echo "avatar:avatar" | chpasswd && adduser avatar sudo
RUN chown -R avatar:avatar /home/avatar
USER avatar

### personal developing settings
RUN mkdir -p /home/avatar/.vim/tmp && echo 'set term=xterm\
""" swp directory\
set directory=~/.vim/tmp' >> /home/avatar/.vimrc

RUN echo '\
export PYTHONPATH=~/projects/avatar2/ \
alias ls="ls --color" \
' >> /home/avatar/.bashrc

### expose use device to container
VOLUME /dev/bus/usb:/dev/bus/usb

### container entry point
CMD ["/bin/bash"]