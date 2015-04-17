FROM ubuntu:latest

MAINTAINER jeroen@jeroenvd.nl

RUN apt-get update
RUN rm -rf /etc/apt/apt.conf.d/docker-gzip-indexes && apt-get update && apt-get -y install apt-show-versions
#RUN apt-get -y install apt-show-versions && apt-get update && apt-get install -f

#install ajenti
RUN wget -O- https://raw.github.com/Eugeny/ajenti/master/scripts/install-ubuntu.sh | sudo sh

#fix to get pure-ftpd working

# install package building helpers
RUN apt-get -y --force-yes install dpkg-dev debhelper

# install dependancies
RUN apt-get -y build-dep pure-ftpd

# build from source
RUN mkdir /tmp/pure-ftpd/ && \
    cd /tmp/pure-ftpd/ && \
    apt-get source pure-ftpd && \
    cd pure-ftpd-* && \
    sed -i '/^optflags=/ s/$/ --without-capabilities/g' ./debian/rules && \
    dpkg-buildpackage -b -uc
    
# install the new deb files
RUN dpkg -i /tmp/pure-ftpd/pure-ftpd-common*.deb
RUN apt-get -y install openbsd-inetd
RUN dpkg -i /tmp/pure-ftpd/pure-ftpd_*.deb

# Prevent pure-ftpd upgrading
RUN apt-mark hold pure-ftpd pure-ftpd-common

#install Ajenti the control panel
RUN apt-get -y install ajenti-v ajenti-v-mail ajenti-v-ftp-pureftpd ajenti-v-php-fpm ajenti-v-nginx ajenti-v-mysql

# Ubuntu default image for some reason does not have tools like Wget/Tar/etc so lets add them
#RUN apt-get update
RUN apt-get -y install wget git

# Git clone scripts repo
RUN cd / && git clone https://github.com/appdesign1987/scripts.git

# Make sure scripts are executable
RUN cd /scripts && chmod +x *.sh

EXPOSE 22 21 80 8000 3306 443 25 993 110

#Start app                                                                                                                                                                                                  
ENTRYPOINT ["/scripts/StartAjenti.sh"]
