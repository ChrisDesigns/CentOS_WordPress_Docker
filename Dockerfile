FROM centos:7

ENV container docker

# Manage systemd for docker
RUN (cd /lib/systemd/system/sysinit.target.wants/; for i in *; do [ $i == \
systemd-tmpfiles-setup.service ] || rm -f $i; done); \
rm -f /lib/systemd/system/multi-user.target.wants/*;\
rm -f /etc/systemd/system/*.wants/*;\
rm -f /lib/systemd/system/local-fs.target.wants/*; \
rm -f /lib/systemd/system/sockets.target.wants/*udev*; \
rm -f /lib/systemd/system/sockets.target.wants/*initctl*; \
rm -f /lib/systemd/system/basic.target.wants/*;\
rm -f /lib/systemd/system/anaconda.target.wants/*;
RUN curl -o /usr/local/bin/systemctl -fL "https://raw.githubusercontent.com/gdraheim/docker-systemctl-replacement/master/files/docker/systemctl.py"
# Repo update
RUN yum install -y epel-release psmisc
RUN yum repolist
# Handle upgrade php to 7.4+ for security
RUN yum install -y http://rpms.remirepo.net/enterprise/remi-release-7.rpm
RUN yum install -y yum-utils
RUN yum-config-manager --enable remi-php74
# See https://make.wordpress.org/hosting/handbook/server-environment/ for more extensions
RUN yum -y install httpd php74 php php-mysql php-pdo php-mbstring
RUN systemctl enable httpd

# Setup based on https://github.com/docker-library/wordpress/blob/master/latest/php7.4/apache/Dockerfile
# Handle setup of wordpress
RUN set -eux; \
	version='6.0'; \
	sha1='7a5a6d0591771e730b05c49d0c3fc134624d0491'; \
	\
	curl -o wordpress.tar.gz -fL "https://wordpress.org/wordpress-$version.tar.gz"; \
	echo "$sha1 *wordpress.tar.gz" | sha1sum -c -; \
	\
# upstream tarballs include ./wordpress/ so this gives us /usr/src/wordpress
	tar -xzf wordpress.tar.gz -C /usr/src/; \
	rm wordpress.tar.gz; \
	\
# https://wordpress.org/support/article/htaccess/
	[ ! -e /usr/src/wordpress/.htaccess ]; \
	{ \
		echo '# BEGIN WordPress'; \
		echo ''; \
		echo 'RewriteEngine On'; \
		echo 'RewriteRule .* - [E=HTTP_AUTHORIZATION:%{HTTP:Authorization}]'; \
		echo 'RewriteBase /'; \
		echo 'RewriteRule ^index\.php$ - [L]'; \
		echo 'RewriteCond %{REQUEST_FILENAME} !-f'; \
		echo 'RewriteCond %{REQUEST_FILENAME} !-d'; \
		echo 'RewriteRule . /index.php [L]'; \
		echo ''; \
		echo '# END WordPress'; \
	} > /usr/src/wordpress/.htaccess; \
	\
	chown -R apache:apache /usr/src/wordpress; \
# pre-create wp-content (and single-level children) for folks who want to bind-mount themes, etc so permissions are pre-created properly instead of root:root
# wp-content/cache: https://github.com/docker-library/wordpress/issues/534#issuecomment-705733507
	mkdir wp-content; \
	for dir in /usr/src/wordpress/wp-content/*/ cache; do \
		dir="$(basename "${dir%/}")"; \
		mkdir "wp-content/$dir"; \
	done; \
	chown -R apache:apache wp-content; \
	chmod -R 777 wp-content

COPY --chown=apache:apache wp-config-docker.php /usr/src/wordpress/

VOLUME /var/www/html
VOLUME [ "/sys/fs/cgroup" ]

WORKDIR /var/www/html

# download and run remaining setup entrypoint
COPY docker-entrypoint.sh /usr/local/bin/
RUN  chmod +x /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["docker-entrypoint.sh"]

EXPOSE 80 443

CMD ["/usr/sbin/init"]

