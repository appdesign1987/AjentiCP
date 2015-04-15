FROM ubuntu:latest

MAINTAINER paimpozhil@gmail.com

RUN apt-get update
RUN rm -rf /etc/apt/apt.conf.d/docker-gzip-indexes && apt-get update && apt-get -y install apt-show-versions
#RUN apt-get -y install apt-show-versions && apt-get update && apt-get install -f


# Centos default image for some reason does not have tools like Wget/Tar/etc so lets add them
#RUN apt-get update
RUN apt-get -y install wget

RUN wget -O- https://raw.github.com/Eugeny/ajenti/master/scripts/install-ubuntu.sh | sudo sh

# install the Mysql / php / git / cron / duplicity / backup ninja
RUN apt-get -y --no-recommends install nano openssh-server git mysql-server php5-mysql \
			  php5-gd php5-mcrypt php5-curl php-soap\
			  php5-cli tar\
			  backupninja duplicity vsftpd

#Apache was installed but we don't need it so we remove it.
RUN apt-get -y remove apache2

#make sure postfix is not installed
RUN apt-get -y remove postfix

#let's cleanup
RUN apt-get -y autoremove

#install Ajenti the control panel
RUN apt-get -y install ajenti-v ajenti-v-ftp-vsftpd ajenti-v-php-fpm ajenti-v-mysql

## fix the locale problems iwth default centos image.. may not be necessary in future. 
#RUN yum -y reinstall glibc-common

# setup the services to start on the container bootup
#RUN chkconfig mysqld on && chkconfig nginx on && chkconfig php-fpm on && chkconfig crond on && chkconfig ajenti on

# defaut centos image seems to have issues with few missing files from this library
#RUN rpm --nodeps -e cracklib-dicts-2.8.16-4.el6.x86_64
#RUN yum -y install cracklib-dicts.x86_64

#allow the ssh root access.. - Diable if you dont need but for our containers we prefer SSH access.
RUN sed -i "s/UsePAM.*/UsePAM no/g" /etc/ssh/sshd_config
RUN sed -i "s/#PermitRootLogin/PermitRootLogin/g" /etc/ssh/sshd_config

#cron needs this fix
RUN sed -i '/session    required   pam_loginuid.so/c\#session    required   pam_loginuid.so' /etc/pam.d/crond

RUN echo 'root:ch@ngem3' | chpasswd

RUN mkdir /scripts
ADD mysqlsetup.sh /scripts/mysqlsetup.sh
RUN chmod 0755 /scripts/*

RUN echo "/scripts/mysqlsetup.sh" >> /etc/rc.d/rc.local

ADD backup /etc/backup.d/

RUN chmod 0600 /etc/backup.* -R


EXPOSE 22 80 8000 3306 443

CMD ["/sbin/init"]
