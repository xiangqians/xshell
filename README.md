# XShell

SSH, SFTP, SCP, RSYNC


# 安装

```shell
# 安装自动化交互式进程工具
$ apt install expect

$ cd /usr/local/src

$ git clone https://github.com/xiangqians/xshell.git

# 将DOS换行符转换为UNIX换行符
#$ sed -i 's/\r$//' xshell.sh

# 创建软链接（symbolic link）
# 'ln': 链接命令
# '-s'：表示创建符号链接，即软链接
# '-f'：表示强制执行操作，即如果目标文件已经存在，则先删除它
$ ln -sf /usr/local/src/xshell/xshell.sh /usr/local/bin/xshell.sh

$ xshell.sh
################################################
#                                              #
# SSH, SFTP, SCP, RSYNC                        #
#                                              #
# Auth  : xiangqian                            #
# Date  : 18:39 ‎2023‎/0‎1‎/‎17                     #‎
# GitHub: https://github.com/xiangqians/xshell #
################################################
XShell  File: /usr/local/bin/xshell.sh -> /usr/local/src/xshell/xshell.sh
Server  File: /usr/local/src/xshell/server.yaml
History File: /usr/local/src/xshell/history

ID  HOST       PORT  USER  PASSWD/KEY-FILE  REM
--  ---------  ----  ----  ---------------  -------
1   127.0.0.1  22    root  ******           example

xshell$ help
  ls      Server List
          Usage: ls
  get     Get Server
          Usage: get {id}
  ssh     Secure Shell
          Usage: ssh {id}
  sftp    SSH File Transfer Protocol
          Usage: sftp {id}
  scp     Secure Copy Protocol
          Usage:
          scp {id} put {local file} {remote file}
          scp {id} get {remote file} {local file}
  rsync   Remote Sync
          Usage:
          rsync {id} put {local file} {remote file}
          rsync {id} get {remote file} {local file}
  history History
          Usage: history
  clear   Clear
          Usage: clear
  quit    Quit
          Usage: quit

xshell$ 
```
