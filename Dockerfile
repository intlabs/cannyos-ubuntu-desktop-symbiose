#
# CannyOS User Storage Dropbox
#
# https://github.com/intlabs/cannyos-ubuntu-desktop-symbiose
#
# Copyright 2014 Pete Birley
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# Pull base image.
FROM intlabs/dockerfile-cannyos-ubuntu-14_04-fuse

# Set environment variables.
ENV HOME /root
ENV DEBIAN_FRONTEND noninteractive

# Set the working directory
WORKDIR /

#****************************************************
#                                                   *
#         INSERT COMMANDS BELLOW THIS               *
#                                                   *
#****************************************************

#Allow remote root login with password
RUN sed -i -e 's/PermitRootLogin without-password/PermitRootLogin yes/g' /etc/ssh/sshd_config && /etc/init.d/ssh restart

# Install nginx
RUN apt-get update && apt-get install -y nginx

# Install php5
RUN apt-get install -y php5-fpm php5-cli php5-mysql

#setup php ini file
RUN sed -i 's/cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g' /etc/php5/fpm/php.ini

#Configure nginx for php
RUN rm -f /etc/nginx/sites-available/default
ADD CannyOS/Desktop/NGINX/server /etc/nginx/sites-available/default

#Install memcache
RUN sudo apt-get install -y php5-memcache memcached php-pear netcat build-essential php5-memcached

# Move into site root
WORKDIR /usr/share/nginx/html

# Clear the deafult site
RUN rm -r -f *
RUN chown -R www-data .

# Put in a php info file
RUN echo '<?php phpinfo(); ?>' > info.php

# Pull in latest version of symbiose
WORKDIR /tmp
RUN apt-get install git -y
RUN git clone https://github.com/symbiose/symbiose.git
RUN cd symbiose && git checkout feat-broadway

#Install grunt
RUN sudo apt-get install -y nodejs npm
RUN ln -s /usr/bin/nodejs /usr/local/bin/node
RUN npm install -g grunt-cli

# Build symbiose
WORKDIR /tmp/symbiose
RUN npm install
RUN grunt build

# Move built system into place
RUN mv build/* /usr/share/nginx/html
RUN rm -f /usr/share/nginx/html/.htaccess


#Fix a bug with the terminal: https://github.com/symbiose/symbiose/issues/367
RUN rm /usr/share/nginx/html/usr/lib/gnome-terminal/gnome-terminal.js
ADD https://raw.githubusercontent.com/symbiose/symbiose/6e5d030a627dc51c955be86d5e4251b0c12eb41b/usr/lib/gnome-terminal/gnome-terminal.js /usr/share/nginx/html/usr/lib/gnome-terminal/gnome-terminal.js


# Fix Permissions
WORKDIR /usr/share/nginx/html
RUN chown -R www-data .



# Cleanup after install
WORKDIR /tmp
RUN rm -r -f symbiose

#****************************************************
#                                                   *
#         ONLY PORT RULES BELLOW THIS               *
#                                                   *
#****************************************************

#SSH
#EXPOSE 22/tcp

#HTTP
EXPOSE 80/tcp

#****************************************************
#                                                   *
#         NO COMMANDS BELLOW THIS                   *
#                                                   *
#****************************************************

# Add startup 
ADD /CannyOS/startup.sh /CannyOS/startup.sh
RUN chmod +x /CannyOS/startup.sh

# Add post-install script
#ADD /CannyOS/post-install.sh /CannyOS/post-install.sh
#RUN chmod +x /CannyOS/post-install.sh

# Define default command.
ENTRYPOINT ["/CannyOS/startup.sh"]