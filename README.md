# xshell

ssh, sftp, scp, rsync terminal

# 安装

## 环境依赖

```shell
$ apt install expect
```

## xshell

```shell
$ cd /usr/local

$ git clone https://github.com/xiangqians/xshell.git

# 创建软链接
$ ln -sf /usr/local/src/xshell/xshell.sh /usr/local/bin/xshell.sh

# 将DOS换行符转换为UNIX换行符
#$ sed -i 's/\r$//' xshell.sh
```

# help

```shell
xshell$ help
```
