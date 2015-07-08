# Image to be used as a base, e.g. one of the official ones:
# https://github.com/docker-library/official-images/blob/master/library/debian
FROM debian:sid

# install packages
RUN apt-get update

# main packages
RUN apt-get install -y grml-debootstrap bats eatmydata

# convenient packages
RUN apt-get install -y curl less vim wget zsh

# grml config
RUN wget -O /root/.vimrc http://git.grml.org/f/grml-etc-core/etc/vim/vimrc
RUN wget -O /root/.zshrc http://git.grml.org/f/grml-etc-core/etc/zsh/zshrc

# nice defaults
ENV LANG C.UTF-8
ENV TERM xterm-256color

# be verbose about package versions
RUN echo 'APT::Get::Show-Versions "1";' > /etc/apt/apt.conf.d/verbose

# cleanup
RUN apt-get clean
RUN rm -rf /var/lib/apt/lists/*

ENTRYPOINT ["/bin/zsh"]
