# xshell

ssh, sftp, scp, rsync terminal


# 安装

```shell
# 安装expect
$ apt install expect

$ cd /usr/local/src

$ git clone https://github.com/xiangqians/xshell.git

# 将DOS换行符转换为UNIX换行符
#$ sed -i 's/\r$//' xshell.sh

# 创建软链接
$ ln -sf /usr/local/src/xshell/xshell.sh /usr/local/bin/xshell.sh

$ xshell.sh
################################################
#                                              #
# ssh, sftp, scp, rsync terminal               #
#                                              #
# Auth  : xiangqian                            #
# Date  : 18:39 ‎2023‎/0‎1‎/‎17                     #‎
# GitHub: https://github.com/xiangqians/xshell #
################################################
XShell  File     : /usr/local/bin/xshell.sh -> /usr/local/src/xshell/xshell.sh
Server  Conf File: /usr/local/src/xshell/server.conf

ID    HOST                 PORT       USER                 PASSWD/KEY-FILE  REM
1     127.0.0.1            22         root                 ******           example

xshell$ help
  ls    server list
        Usage: ls
  get   get server
        Usage: get {id}
  ssh
        Usage: ssh {id}
  sftp
        Usage: sftp {id}
  scp
        Usage:
        scp {id} put {local file} {remote file}
        scp {id} get {remote file} {local file}
  rsync
        Usage:
        rsync {id} put {local file} {remote file}
        rsync {id} get {remote file} {local file}
  quit  quit
        Usage: quit

xshell$ 
```
