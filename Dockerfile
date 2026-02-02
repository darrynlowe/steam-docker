FROM archlinux:latest

# Enable multilib repo
RUN echo -e "\n[multilib]\nInclude = /etc/pacman.d/mirrorlist" >> /etc/pacman.conf && \
    pacman -Syu --noconfirm

RUN pacman -Sl multilib 

# Install required packages
RUN pacman -S --noconfirm \
        xorg-server \
	xorg-server-common \
        xorg-xinit \
        xorg-xrandr \
        xterm \
        mesa \
        git \
        sudo \
	bash \
	base-devel

RUN pacman -S --noconfirm \
    xf86-input-libinput \
    xf86-input-evdev 

RUN echo -e "\n[steam-libs]\nSigLevel = Optional DatabaseOptional\nServer = https://damglador.github.io/\$repo/\$arch/" >> /etc/pacman.conf && \
    pacman -Syu --noconfirm

RUN pacman -S --noconfirm \
    xorg-fonts-misc \
    xorg-fonts

RUN pacman -Syu --noconfirm --needed \
    openbox \
    less \
    vim \
    inetutils \ 
    tigervnc \
    pciutils \
    libva \ 
    libva-utils 

RUN pacman -Syu --noconfirm --needed \
            avahi \
            dbus \
            lib32-fontconfig \
            fuse2 \
            x11vnc \
            xorg \
            xorg-apps \
            xorg-font-util \
            xorg-fonts-misc \
            xorg-fonts-type1 \
            xorg-server \
            xorg-server-xephyr \
            xorg-server-xvfb \
            xorg-xauth \
            xorg-xbacklight \
            xorg-xhost \
            xorg-xinit \
            xorg-xinput \
            xorg-xkill \
            xorg-xprop \
            xorg-xrandr \
            xorg-xsetroot \
            xorg-xwininfo \
            xf86-input-evdev \
            xterm \
            gamescope

# Add a non-root user (recommended for yay)
RUN useradd -m builder && echo "builder ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
USER builder
WORKDIR /home/builder

# Install yay
RUN git clone https://aur.archlinux.org/yay.git && \
    cd yay && \
    makepkg -si --noconfirm

RUN yay -S --noconfirm \
    nvidia-580xx-utils \
    lib32-nvidia-580xx-utils
#    nvidia-580xx-settings


RUN yay -S --noconfirm lib32-openssl-1.1 openssl-1.1

RUN yay -S --noconfirm steam-native-runtime

RUN yay -S --noconfirm protontricks


USER root


RUN pacman -S --noconfirm \
    vulkan-tools \
    mesa-utils

RUN pacman -S --noconfirm --needed \
    pulseaudio \
    pulseaudio-alsa \
    alsa-lib \
    alsa-utils

RUN pacman -S --noconfirm \
    fluxbox

RUN pacman -S --noconfirm \
    python-pip

RUN python3 -m pip install \
            --break-system-packages \
            --pre \
            --upgrade \
            --no-cache-dir \
            git+https://github.com/Steam-Headless/dumb-udev.git

# configure locales
RUN sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
    locale-gen && \
    echo 'LANG=en_US.UTF-8' > /etc/locale.conf && \
    echo 'LC_ALL=en_US.UTF-8' >> /etc/locale.conf

# configure X
RUN pacman -S --noconfirm xorg-mkfontscale xorg-fonts-misc && \
    mkfontdir /usr/share/fonts/misc && \
    mkfontdir /usr/share/fonts/75dpi && \
    mkfontdir /usr/share/fonts/100dpi


# Create a minimal xorg.conf
COPY etc/X11/xorg.conf /etc/X11/xorg.conf

# Set up the sound
COPY etc/asound.conf /etc/asound.conf

# Copy start script
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

COPY start-x.sh /usr/local/bin/start-x.sh
RUN chmod +x /usr/local/bin/start-x.sh

# Set environment
ENV DISPLAY=:55

RUN usermod -l darryn builder && \
    groupmod -n darryn builder && \
    usermod -s /bin/bash darryn && \
    usermod -d /home/darryn darryn && \
    sed -i 's/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

RUN groupmod -g 994 -o input \
 && groupmod -g 989 -o render \
 && groupmod -g 996 -o audio \
 && groupmod -g 997 -o utmp \
 && groupmod -g 5 -o tty \
 && usermod -aG wheel,input,render,audio,tty,utmp darryn

# Enable SSH (note: the config files are mounted from the docker host)
RUN mkdir /var/run/sshd
RUN mkdir /run/user/1000
RUN chown darryn:darryn /run/user/1000

WORKDIR /home/darryn

CMD ["/usr/local/bin/entrypoint.sh"]

