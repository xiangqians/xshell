#!/bin/bash

##################################################
# auth: xiangqian
# date: 18:39 ‎2023‎/0‎1‎/‎17‎
# link: https://github.com/xiangqians/sf-terminal
##################################################


# 双引号会先解析变量的内容
# 单引号包裹的内容表示原样输出

# 当前目录
cdir=$(cd $(dirname $0); pwd)
#echo cdir $cdir

# 获取当前软链接所指向的文件（sf_terminal.sh）路径，如果存在软链接的话
# $ ln [options] source dist
# $ ln -s source dist
fpath=$(ls -al $0 | awk '{print $NF}')
#echo fpath $fpath
# 获取 sf_terminal.sh 所在的真实目录
fdir=${fpath%/*}
#echo fdir $fdir

# test
fdir="/cygdrive/c/Users/xiangqian/Desktop/tmp/sf-terminal"

# server配置
svrconf="${fdir}/sf_terminal_svr.conf"

# 判断文件是否存在
if [ ! -f $svrconf ]; then
	# 退出程序
	#printf "%s: No such file\n" "${svrconf}"
	#exit 1
	
	# 文件不存在则创建
	touch $svrconf
	# $? 获取上一个命令执行结果，如果非0（异常）则退出程序
	if [ $? -ne 0 ]; then
		exit 1
	fi
fi

# code
CodeNormal=0
CodeInvalidId=1
CodeIdNotExist=2
CodeInvalidSvr=3
CodeInvalidParam=4

# 字符串转为数组
function ConvStrToArrFunc(){
	str="$1"
	
	# 以空格分隔字符串，通过 IFS 变量设置分隔符
	# 保存当前shell默认的分割符
	OLD_IFS="$IFS"
	# 将shell的分割符号改为空格
	IFS=' '
	arr=(${str})
	# 恢复shell默认分割符配置
	IFS="$OLD_IFS"
	# 数组内容
	#echo ${arr[@]}
	# 数组长度
	#echo ${#arr[@]} # OR ${#arr[*]}
	
	# 获取返回值方式一：return
	# 获取返回值：（使用 $? 获取返回值）
	# ConvStrToArrFunc 'test'
	# echo $?
	#return 0

	# 获取返回值方式二：echo
	# 获取返回值：
	# r=($(ConvStrToArrFunc 'test'))
	# echo ${#r[*]} ${r[*]}
	echo ${arr[*]}
}

# server列表
function ListFunc(){
	# format
	format='%-3s %-18s %-8s %-20s %-8s %s\n'
	printf "${format}" 'ID' 'HOST' 'PORT' 'USER' 'PASSWD' 'REM'
	
	# server id
	id=1
	#while read line; do
	while read line || [ -n "$line" ]; do
		#echo $id $line
		arr=($(ConvStrToArrFunc "$line"))
		#echo ${#arr[*]} ${arr[*]}
		# 数组长度校验
		if [ ${#arr[@]} -ne 5 ]; then
			printf "unable to parse $svrconf\n"
			exit 1
		fi
		
		host=${arr[0]}
		port=${arr[1]}
		user=${arr[2]}
		#passwd=${arr[3]}
		passwd="******"
		rem=${arr[4]}
		
		printf "${format}" "$id" "${host}" "${port}" "${user}" "${passwd}" "${rem}"
		
		# id++
		let id++
	done < $svrconf
}

# server数量
function NFunc(){
	n=$(sed -n '$=' $svrconf)
	return $n
}

# 校验id是否合法
function CheckIdFunc(){
	id=$1
	expr $id "+" 10 &> /dev/null
	if [ $? -ne 0 ]; then
		return $CodeInvalidId
	fi
	
	id=$((id+0))
	NFunc
	n=$?
	if [ $id -le 0 ] || [ $id -gt $n ]; then
		return $CodeIdNotExist
	fi
	
	return $CodeNormal
}

# 新增server
function AddFunc(){
	svr=$1
	if [[ $svr == "" ]]; then
		return $CodeInvalidSvr
	fi
	
	arr=($(ConvStrToArrFunc "$svr"))
	if [ ${#arr[*]} -ne 5 ]; then
		return $CodeInvalidSvr
	fi
	
	# 添加到文件末尾
	# sed -i 空文件无法添加
	#sed -i '$a \'"$svr" $svrconf
	# 使用 >> 添加
	echo "$svr" >> $svrconf
	return $CodeNormal
}

# 删除server
function DelFunc(){
	id=$1
	CheckIdFunc "$id"
	r=$?
	if [ $r -ne 0 ]; then
		return $r
	fi
	
	sed -i "${id}d" $svrconf
	return $CodeNormal
}

# 修改server
function UpdFunc(){
	svr=$1
	arr=($(ConvStrToArrFunc "$svr"))
	
	# 校验参数为奇数个
	len=${#arr[@]}
	r=$((len % 2))
	if [ $len -eq 1 ] || [ $r -ne 1 ]; then
		return $CodeInvalidParam
	fi
	
	# 校验id
	id=${arr[0]}
	CheckIdFunc "$id"
	r=$?
	if [ $r -ne 0 ]; then
		return $r
	fi
	
	oldSvr=$(sed -n "${id}p" $svrconf)
	oldArr=($(ConvStrToArrFunc "$oldSvr"))
	
	idx=1
	oldIdx=0
	while [ $idx -lt $len ]; do
		p=${arr[$idx]}
		#echo $p
		# host
		if [[ $p == '-h' ]]; then
			oldIdx=0
			
		# port
		elif [[ $p == '-P' ]]; then
			oldIdx=1
			
		# user
		elif [[ $p == '-u' ]]; then
			oldIdx=2
			
		# passwd
		elif [[ $p == '-p' ]]; then
			oldIdx=3
			
		# rem
		elif [[ $p == '-r' ]]; then
			oldIdx=4
		
		# command not found
		else
			printf "%s: command not found\n" "${p}"
			return $CodeNormal
		fi
		
		# v
		let idx++
		v=${arr[$idx]}
		oldArr[$oldIdx]=$v
		
		let idx++
	done
	
	#echo oldArr ${oldArr[*]}
	oldSvr=${oldArr[@]}
	#echo oldSvr $oldSvr
	# 先新增，再删除
	oldId=$((id+1))
	sed -i "${id}i\\$oldSvr" $svrconf && sed -i "${oldId}d" $svrconf
	
	return $CodeNormal
}

# 查询server信息
function QryFunc(){
	id=$1
	CheckIdFunc "$id"
	r=$?
	if [ $r -ne 0 ]; then
		return $r
	fi
	
	svr=$(sed -n "${id}p" $svrconf)
	arr=($(ConvStrToArrFunc "$svr"))
	host=${arr[0]}
	port=${arr[1]}
	user=${arr[2]}
	passwd=${arr[3]}
	rem=${arr[4]}
	printf 'host\t: %s\n' "${host}"
	printf 'port\t: %s\n' "${port}"
	printf 'user\t: %s\n' "${user}"
	printf 'passwd\t: %s\n' "${passwd}"
	printf 'rem\t: %s\n' "${rem}"
	
	return $CodeNormal
}

# ssh or sftp
function SshOrSftpFunc(){
	# 校验id
	id=$1
	CheckIdFunc "$id"
	r=$?
	if [ $r -ne 0 ]; then
		return $r
	fi
	
	type=$2
	
	# ssh
	if [[ $type == 'ssh' ]]; then
		fpath=${fdir}/sf_terminal_ssh.sh
		cat>${fpath}<<EOF
#!/usr/bin/expect

# 
set host [lindex \$argv 0]
set port [lindex \$argv 1]
set user [lindex \$argv 2]
set passwd [lindex \$argv 3]

# timeout
#set timeout -1
set timeout 60
spawn /usr/bin/ssh \${user}@\${host} -p \${port}
expect {
    "*yes/no*" { send "yes\r"; exp_continue }
    #"*assword:*" { send "\${passwd}\r" }
    "*assword:*" { send "\${passwd}\n" }
}
interact
EOF

	# sftp
	elif [[ $type == 'sftp' ]]; then
		fpath=${fdir}/sf_terminal_sftp.sh
		cat>${fpath}<<EOF
#!/usr/bin/expect

# 
set host [lindex \$argv 0]
set port [lindex \$argv 1]
set user [lindex \$argv 2]
set passwd [lindex \$argv 3]

# timeout
#set timeout -1
set timeout 60
spawn /usr/bin/sftp -P \$port \$user@\$host
expect {
    "*yes/no*" { send "yes\r"; exp_continue }
    "*assword:*" { send "\${passwd}\r" }
}
interact
EOF
	
	# put
	printf '  %s\t%s\n' 'put' ''
	printf '  \t%s\n' 'Usage: put [-r] {local_file_name} {remote_file_name}'
	# get
	printf '  %s\t%s\n' 'get' ''
	printf '  \t%s\n' 'Usage: get [-r] {remote_file_name} {local_file_name}'
	printf '\n'

	else
		printf 'unknown error\n'
		exit 1
	fi
	
	# server
	svr=$(sed -n "${id}p" $svrconf)
	#echo svr $svr
	arr=($(ConvStrToArrFunc "$svr"))
	host=${arr[0]}
	port=${arr[1]}
	user=${arr[2]}
	passwd=${arr[3]}
	expect ${fpath} "${host}" "${port}" "${user}" "${passwd}"
	
	return $CodeNormal
}

# ssh
function SshFunc(){
	SshOrSftpFunc "$1" 'ssh'
	return $?
}

# sftp
function SftpFunc(){
	SshOrSftpFunc "$1" 'sftp'
	return $?
}

# scp（secure copy）是一个基于 SSH 协议在网络之间进行安全传输的命令。
function ScpFunc(){
	arr=($(ConvStrToArrFunc "$1"))
	
	# 校验参数个数
	len=${#arr[@]}
	if [ $len -ne 4 ]; then
		return $CodeInvalidParam
	fi
	
	# 类型：put,get
	type=${arr[0]}
	
	# 校验id
	id=${arr[1]}
	CheckIdFunc "$id"
	r=$?
	if [ $r -ne 0 ]; then
		return $r
	fi
	
	fname1=${arr[2]}
	if [[ $fname1 == "" ]]; then
		return $CodeInvalidParam
	fi
	
	fname2=${arr[3]}
	if [[ $fname2 == "" ]]; then
		return $CodeInvalidParam
	fi
	
	# put
	# 从本地拷贝到远程
	if [[ $type == 'put' ]]; then
		# local file name
		lfname=$fname1
		# remote file name
		rfname=$fname2
		
		# script file name
		sfname=${fdir}/sf_terminal_scp_put.sh
		cat>${sfname}<<EOF
#!/usr/bin/expect

# 获取参数
set host [lindex \$argv 0]
set port [lindex \$argv 1]
set user [lindex \$argv 2]
set passwd [lindex \$argv 3]
# local file name
set lfname [lindex \$argv 4]
# remote file name
set rfname [lindex \$argv 5]

# timeout
#set timeout -1
set timeout 60
# -v 输出详细信息
# -P 指定远程主机的 sshd 端口号
# -p 保留文件的访问和修改时间
# -r 递归复制目录及其内容
# -C 在复制过程中压缩文件或目录
# -6 使用 IPv6 协议
spawn scp -v -r -p -P \${port} \${lfname} \${user}@\${host}:\${rfname}
expect {
    "*yes/no*" { send "yes\r"; exp_continue }
    #"*assword:*" { send "\${passwd}\r" }
    "*assword:*" { send "\${passwd}\n" }
}
interact
EOF

	# 从远程拷贝到本地
	elif [[ $type == 'get' ]]; then
		# local file name
		lfname=$fname2
		# remote file name
		rfname=$fname1
		
		# script file name
		sfname=${fdir}/sf_terminal_scp_get.sh
		cat>${sfname}<<EOF
#!/usr/bin/expect

# 获取参数
set host [lindex \$argv 0]
set port [lindex \$argv 1]
set user [lindex \$argv 2]
set passwd [lindex \$argv 3]
# local file name
set lfname [lindex \$argv 4]
# remote file name
set rfname [lindex \$argv 5]

# timeout
#set timeout -1
set timeout 60
# -v 输出详细信息
# -P 指定远程主机的 sshd 端口号
# -p 保留文件的访问和修改时间
# -r 递归复制目录及其内容
# -C 在复制过程中压缩文件或目录
# -6 使用 IPv6 协议
spawn scp -v -r -p -P \${port} \${user}@\${host}:\${rfname} \${lfname} 
expect {
    "*yes/no*" { send "yes\r"; exp_continue }
    #"*assword:*" { send "\${passwd}\r" }
    "*assword:*" { send "\${passwd}\n" }
}
interact
EOF

	else
		printf "%s: command not found\n" "${type}"
		return $CodeNormal
	fi
	
	# server
	svr=$(sed -n "${id}p" $svrconf)
	#echo svr $svr
	arr=($(ConvStrToArrFunc "$svr"))
	host=${arr[0]}
	port=${arr[1]}
	user=${arr[2]}
	passwd=${arr[3]}
	expect ${sfname} "${host}" "${port}" "${user}" "${passwd}" "${lfname}" "${rfname}"
	
	return $CodeNormal
}

# pwd
function PwdFunc(){
	P=1
	
	arr=($(ConvStrToArrFunc "$1"))
	idx=0
	while [ $idx -lt ${#arr[@]} ]; do
		p=${arr[$idx]}
		if [[ $p == '-P' ]]; then
			P=0
		else
			printf "%s: command not found\n" "${p}"
			return $CodeNormal
		fi
		let idx++
	done
	
	if [ $P -eq 0 ]; then 
		printf '%s\n' "$fdir"
	else
		printf '%s\n' "$cdir"
	fi
	
	return $CodeNormal
}

# 当前时间
function NowFunc(){
	echo `date "+%Y-%m-%d %H:%M:%S.%N"`
}

function PrintCodeMsg(){
	code=$1
	#echo code $code
	if [ $code -eq $CodeInvalidId ]; then
		printf 'invalid id\n'

	elif [ $code -eq $CodeIdNotExist ]; then
		printf 'id does not exist\n'
		
	elif [ $code -eq $CodeInvalidSvr ]; then
		printf 'invalid server\n'
	
	elif [ $code -eq $CodeInvalidParam ]; then
		printf 'invalid parameter\n'
	fi
}

function HelpFunc(){
	# ls
	printf '  %s\t%s\n' 'ls' 'server list'
	printf '  \t%s\n' 'Usage: ls'
	
	# add
	printf '  %s\t%s\n' 'add' 'add server'
	printf '  \t%s\n' 'Usage: add {host} {port} {user} {passwd} {rem}'
	
	# del
	printf '  %s\t%s\n' 'del' 'delete server'
	printf '  \t%s\n' 'Usage: del {id}'
	
	# upd
	printf '  %s\t%s\n' 'upd' 'update server'
	printf '  \t%s\t%s\n' 'Usage: upd {id} [-h {host}] [-P {port}] [-u {user}] [-p {passwd}] [-r {rem}]'
	printf '  \t%s\t%s\n' '-h' 'host'
	printf '  \t%s\t%s\n' '-P' 'port'
	printf '  \t%s\t%s\n' '-u' 'user'
	printf '  \t%s\t%s\n' '-p' 'passwd'
	printf '  \t%s\t%s\n' '-r' 'rem'
	
	# qry
	printf '  %s\t%s\n' 'qry' 'query server'
	printf '  \t%s\n' 'Usage: qry {id}'
	
	# ssh
	printf '  %s\t%s\n' 'ssh' 'ssh'
	printf '  \t%s\t%s\n' 'Usage: ssh {id}'
	
	# sftp
	printf '  %s\t%s\n' 'sftp' 'sftp'
	printf '  \t%s\t%s\n' 'Usage: sftp {id}'
	
	# scp
	printf '  %s\t%s\n' 'scp' ''
	printf '  \t%s\t%s\n' 'Usage: scp put {id} {local_file_name} {remote_file_name}'
	printf '  \t%s\t%s\n' 'Usage: scp get {id} {remote_file_name} {local_file_name}'
	
	# pwd
	printf '  %s\t%s\n' 'pwd' 'Print the name of the current working directory'
	printf '  \t%s\t%s\n' 'Usage: pwd [-P]'
	printf '  \t%s\t%s\n' '-P' 'print the physical directory, without any symbolic links'
	
	# now
	printf '  %s\t%s\n' 'now' 'current time'
	printf '  \t%s\t%s\n' 'Usage: now'
	
	# q
	printf '  %s\t%s\n' 'q' 'quit'
	printf '  \t%s\n' 'Usage: q'
}

ListFunc

while true; do
	printf '\n'
	read -p 'sf-terminal$ ' p
	#echo $p	
	if [[ $p == '' ]]; then
		continue
	
	# 帮助命令
	elif [[ $p == 'h' ]]; then
		HelpFunc
		continue
	
	# ls
	elif [[ $p == 'ls' ]]; then
		ListFunc
		continue
	
	# add
	elif [[ $p == 'add '* ]]; then
		AddFunc "${p: 4}"
		PrintCodeMsg $?
		continue
	
	# del
	elif [[ $p == 'del '* ]]; then
		DelFunc "${p: 4}"
		PrintCodeMsg $?
		continue
	
	# upd
	elif [[ $p == 'upd '* ]]; then
		UpdFunc "${p: 4}"
		PrintCodeMsg $?
		continue
	
	# qry
	elif [[ $p == 'qry '* ]]; then
		QryFunc "${p: 4}"
		PrintCodeMsg $?
		continue
	
	# ssh
	elif [[ $p == 'ssh '* ]]; then
		SshFunc "${p: 4}"
		PrintCodeMsg $?
		continue
	
	# sftp
	elif [[ $p == 'sftp '* ]]; then
		SftpFunc "${p: 5}"
		PrintCodeMsg $?
		continue
	
	# scp
	elif [[ $p == 'scp '* ]]; then
		ScpFunc "${p: 4}"
		PrintCodeMsg $?
		continue
	
	# pwd
	elif [[ $p == 'pwd' ]]; then
		PwdFunc ""
		PrintCodeMsg $?
		continue
	elif [[ $p == 'pwd '* ]]; then
		PwdFunc "${p: 4}"
		PrintCodeMsg $?
		continue
		
	# 当前时间
	elif [[ $p == 'now' ]]; then
		NowFunc
		continue
	
	# quit
	elif [[ $p == 'q' ]]; then
		break
	
	# command not found
	else
		printf "%s: command not found\n" "${p}"
		continue
	fi
done

exit 0