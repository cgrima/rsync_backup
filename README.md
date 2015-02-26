# rsync_backup
Rsync_backup does incremental backups (with hard links) and keeps the last backups over a defined time period (rotation).
i.e. the total size of five backups for the folder "toto" is not 5x "toto" but 1x "toto" + the modified files from within "toto".

The destination folder can be either local or on a remote SSH server.

## Usage
```sh
$ rsync_backup.sh task
```
where 'task' is a file gathering all the settings for your backup. 'Dummy task' is a commented dummy file for a backup task.

## Example
For a task called "backup_toto" and defined as:

	$ cat backup_toto
	
	SIMULATION=0
	HOLD="30"
	SRC_PTH="/path/to/folder/"
	SRC_FLD="toto"
	EXCLUDE="--exclude=*_NOBACKUP/"
	DST_PTH="/my/backup/folder/"
	LOG="/my/log/folder/${SRC_FLD}_backup.log"

then,

	$ rsync_backup.sh backup_toto

will backup the content of **/path/to/folder/toto** into **/my/backup/folder/toto_yyyy-mm-dd** where *yyyy-mm-dd* is the current date. A log file is also ceated **/my/log/folder/toto_backup.log** 

If you run this as a weekly job in crontab, your backup folder will be populated this way:

	/my/backup/folder/toto_2015-02-26
	/my/backup/folder/toto_2015-02-19
	/my/backup/folder/toto_2015-02-12
	/my/backup/folder/toto_2015-02-05
	/my/backup/folder/toto_2015-02-30

The redundant content of each folder is hard-linked. Backup folders older than the defined 30 days are deleted.

## Remote SSH server
if the backup folder is located on a remote SSH server, you can add the server settings in the 'task' file, such as:

	LOGIN="toto"
	SERVER_IP="www.mybackupserver.net"
	PORT="22"
	RSA_KEY="/RSA/key/location"
