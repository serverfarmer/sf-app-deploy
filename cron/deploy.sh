#!/bin/bash

if [ "$3" = "" ]; then
	echo "usage: $0 <app-name> <app-directory> <deploy-key-name> [email] [...]"
	exit 1
elif ! [[ $1 =~ ^[a-z0-9-]+$ ]]; then
	echo "error: parameter $1 not conforming application name format"
	exit 1
elif [ ! -d $2 ]; then
	echo "invalid application directory $2"
	exit 1
elif [ ! -f ~/.ssh/$3 ]; then
	echo "git key $3 not found"
	exit 1
fi

app=$1
target=$2
key=$3
shift
shift
shift

module="`basename $target`"
logpath="/var/log/deploy-$app/`date +%Y`"
mkdir -m 0710 -p $logpath

tmp="$logpath/tmp.$$.log"
log="$logpath/$module-`date +%Y%m%d-%H%M`.$$.log"

touch $tmp
cd $target

if [ -x /etc/local/hooks/pre-deploy-$app.sh ]; then
	/etc/local/hooks/pre-deploy-$app.sh $target >>$tmp
fi

if [ "`whoami`" != "root" ] && [ -x $target/build-prepare.sh ]; then
	$target/build-prepare.sh >>$tmp
fi

GIT_SSH=/opt/farm/scripts/git/helper.sh GIT_KEY=~/.ssh/$key git pull 2>&1 |grep -v "Already up-to-date" >>$tmp

if [ "`whoami`" != "root" ] && [ -x $target/build.sh ]; then
	$target/build.sh >>$tmp
fi

if [ -x /etc/local/hooks/post-deploy-$app.sh ]; then
	/etc/local/hooks/post-deploy-$app.sh $target >>$tmp
fi

if [ ! -s $tmp ]; then
	rm -f $tmp
else
	mv -f $tmp $log
	needle="Please make sure you have the correct access rights"

	if grep -q "$needle" $log; then
		status="failure"
	else
		status="success"
	fi

	subject="Deployment status:$status for $app/$module"

	for addr in $@; do
		cat $log |mail -s "$subject" $addr
	done
	gzip -9 $log
fi
