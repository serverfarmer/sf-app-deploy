#!/bin/bash

if [ "$3" = "" ]; then
	echo "usage: $0 <app-name> <app-directory> <app-user> <git-url> <deploy-key-name> [email] [...]"
	exit 1
elif ! [[ $1 =~ ^[a-z0-9-]+$ ]]; then
	echo "error: parameter $1 not conforming application name format"
	exit 1
elif ! [[ $3 =~ ^[a-z0-9._-]+$ ]]; then
	echo "error: parameter $3 not conforming user name format"
	exit 1
elif [ -d $2 ]; then
	echo "application directory $2 already exists"
	exit 1
elif [ "`getent passwd $3`" = "" ]; then
	echo "user $3 not found"
	exit 1
elif [ ! -f ~/.serverfarmer/ssh/$5 ]; then
	echo "git key $5 not found"
	exit 1
fi

app=$1
target=$2
user=$3
giturl=$4
key=$5
shift
shift
shift
shift
shift

GIT_SSH=/opt/farm/scripts/git/helper.sh GIT_KEY=~/.serverfarmer/ssh/$key git clone $giturl $target

if [ ! -d $target ]; then
	echo "aborting application setup due to above git problem"
	exit 1
fi

group="`groups $user |cut -d' ' -f3`"

logpath="/var/log/deploy-$app/"
mkdir -m 0710 -p $logpath
chown $user:$group $logpath
chown -R $user:$group $target
mkdir -p ~/.serverfarmer/hooks

if [ ! -f ~/.serverfarmer/hooks/pre-deploy-$app.sh ]; then
	echo '#!/bin/sh' >~/.serverfarmer/hooks/pre-deploy-$app.sh
fi

if [ ! -f ~/.serverfarmer/hooks/post-deploy-$app.sh ]; then
	echo '#!/bin/sh' >~/.serverfarmer/hooks/post-deploy-$app.sh
fi

chmod +x ~/.serverfarmer/hooks/pre-deploy-$app.sh ~/.serverfarmer/hooks/post-deploy-$app.sh

echo "
*/15 * * * * $user /opt/farm/ext/app-deploy/cron/deploy.sh  $app $target $key  $@
" >>/etc/crontab
