## Overview

`sf-app-deploy` extension is a minimalistic approach to CI/CD processes, designed for software houses having multiple customers with rather simple
applications (one server, one repository, database changes done by the application itself, moderate web traffic, no strict security requirements).

## How it works

`sf-app-install` script installs the application - you just need to supply:

- application name (eg. myapp)
- target directory (eg. /var/www/myapp)
- system user with write permissions (eg. www-data)
- repository url (eg. `ssh://git@github.com/mycompany/myapp`)
- deployment key (eg. id_myapp, it should be located in `~/.serverfarmer/ssh` directory of given user)
- list of email addresses to notify after each deployment (optional)

`sf-app-install myapp /var/www/myapp www-data ssh://git@github.com/mycompany/myapp id_myapp john.doe@company.com`

This will clone the repository to chosen target directory, set proper permissions for everything, and add entry to `/etc/crontab` file (which can be customized later).

`cron/deploy.sh` script will run every 15 minutes by default, each time trying to pull changes from application repository, and executing pre/post build hook scripts.

When no changes are detected, and none of hook scripts will report an error, no report is stored, and the application is considered unchanged.
Otherwise, report file is stored in `/var/log/deploy-myapp` directory and sent to all email addresses passed previously to `sf-app-install`.

## Hook scripts

For most applications, it's not enough just to "git pull". `cron/deploy.sh` can execute a few types of build scripts, containing custom build logic:

1. Global hook scripts, located in `~/.serverfarmer/hooks` directory: `pre-deploy-myapp.sh` and `post-deploy-myapp.sh`, run respectively before and after pulling changes from application repository.

2. Local hook scripts `build-prepare.sh` and `build.sh`, located directly in application directory (and thus in repository, so developers can edit their code). There scripts are run
only if the application uses system user different than `root` (ew. `www-data`).

## Execution order

1. `~/.serverfarmer/hooks/pre-deploy-myapp.sh`

2. `/var/www/myapp/build-prepare.sh`
- executed **before updating the code**
- skipped if all the process runs as `root`

3. `git pull`

4. `/var/www/myapp/build.sh`
- skipped if all the process runs as `root`

5. `~/.serverfarmer/hooks/post-deploy-myapp.sh`
