#!/bin/sh

if grep -q /opt/farm/ext/app-deploy/cron /etc/crontab; then
	sed -i -e "/\/opt\/farm\/ext\/app-deploy\/cron/d" /etc/crontab
fi

if [ -h /usr/local/bin/app-install ]; then
	rm -f /usr/local/bin/app-install
fi
