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
fname=$(ls -al $0 | awk '{print $NF}')
#echo fname $fname
# 获取 sf_terminal.sh 所在的真实目录
fdir=${fname%/*}
#echo fdir $fdir

# data dir
ddir=$fdir
#ddir="/cygdrive/c/Users/xiangqian/Desktop/tmp/sf-terminal"

# server conf name
svrconfname="${ddir}/sf_terminal_svr.conf"

# 判断文件是否存在
if [ ! -f $svrconfname ]; then
	# 退出程序
	#printf "%s: No such file\n" "${svrconfname}"
	#exit 1
	
	# 文件不存在则创建
	touch $svrconfname
	# $? 获取上一个命令执行结果，如果非0（异常）则退出程序
	if [ $? -ne 0 ]; then
		exit 1
	fi
fi

# code
CodeNormal=0
CodeInvalidId=1
CodeInvalidParam=2
CodeIdNotExist=3
CodeParamNumNotMatch=4

# 打印code消息
function PrintCodeMsg(){
	code=$1
	#echo code $code
	if [ $code -eq $CodeInvalidId ]; then
		printf 'invalid id\n'

	elif [ $code -eq $CodeInvalidParam ]; then
		printf 'invalid parameter\n'
	
	elif [ $code -eq $CodeIdNotExist ]; then
		printf 'id does not exist\n'
	
	elif [ $code -eq $CodeParamNumNotMatch ]; then
		printf 'the number of parameters does not match\n'
	fi
}

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
			printf "unable to parse $svrconfname\n"
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
	done < $svrconfname
}

# server数量
function NFunc(){
	n=$(sed -n '$=' $svrconfname)
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
		return $CodeInvalidParam
	fi
	
	arr=($(ConvStrToArrFunc "$svr"))
	if [ ${#arr[*]} -ne 5 ]; then
		return $CodeInvalidParam
	fi
	
	# 添加到文件末尾
	# sed -i 空文件无法添加
	#sed -i '$a \'"$svr" $svrconfname
	# 使用 >> 添加
	echo "$svr" >> $svrconfname
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
	
	sed -i "${id}d" $svrconfname
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
	
	oldsvr=$(sed -n "${id}p" $svrconfname)
	oldarr=($(ConvStrToArrFunc "$oldsvr"))
	
	idx=1
	oldidx=0
	while [ $idx -lt $len ]; do
		p=${arr[$idx]}
		#echo $p
		# host
		if [[ "$p" == '-h' ]]; then
			oldidx=0
			
		# port
		elif [[ "$p" == '-P' ]]; then
			oldidx=1
			
		# user
		elif [[ "$p" == '-u' ]]; then
			oldidx=2
			
		# passwd
		elif [[ "$p" == '-p' ]]; then
			oldidx=3
			
		# rem
		elif [[ "$p" == '-r' ]]; then
			oldidx=4
		
		# command not found
		else
			printf "%s: command not found\n" "${p}"
			return $CodeNormal
		fi
		
		# v
		let idx++
		v=${arr[$idx]}
		oldarr[$oldidx]=$v
		
		let idx++
	done
	
	#echo oldarr ${oldarr[*]}
	oldsvr=${oldarr[@]}
	#echo oldsvr $oldsvr
	# 先新增，再删除
	oldid=$((id+1))
	sed -i "${id}i\\$oldsvr" $svrconfname && sed -i "${oldid}d" $svrconfname
	
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
	
	svr=$(sed -n "${id}p" $svrconfname)
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

# execute script file
function ExecSFFunc(){	
	# 脚本文件类型
	type=$1
	
	# server id
	id=$2
	
	# local file name
	lfname=$3
	
	# remote file name
	rfname=$4

	# 校验id
	CheckIdFunc "$id"
	r=$?
	if [ $r -ne 0 ]; then
		return $r
	fi
	
	# script file name
	sfname=${ddir}/sf_terminal_script.sh
	cat>${sfname}<<EOF
#!/usr/bin/expect

# type
set type [lindex \$argv 0]
# host
set host [lindex \$argv 1]
# port
set port [lindex \$argv 2]
# user
set user [lindex \$argv 3]
# passwd
set passwd [lindex \$argv 4]
# local file name
set lfname [lindex \$argv 5]
# remote file name
set rfname [lindex \$argv 6]

# timeout
#set timeout -1
set timeout 60

if { "\$type" == "ssh" } {
	spawn /usr/bin/ssh \${user}@\${host} -p \${port}

} elseif { "\$type" == "sftp" } {
	# put
	puts "  put"
	puts "  \tUsage: put \[-r\] {local_file_name} {remote_file_name}"
	# get
	puts "  get"
	puts "  \tUsage: get \[-r\] {remote_file_name} {local_file_name}"
	puts ""
	# spawn
	spawn /usr/bin/sftp -P \$port \$user@\$host

} elseif { "\$type" == "scp_put" } {
	# scp（secure copy）是一个基于 SSH 协议在网络之间进行安全传输的命令。
	# -v 输出详细信息
	# -P 指定远程主机的 sshd 端口号
	# -p 保留文件的访问和修改时间
	# -r 递归复制目录及其内容
	# -C 在复制过程中压缩文件或目录
	# -6 使用 IPv6 协议
	
	# 从本地拷贝到远程
	spawn scp -v -r -p -C -P \${port} \${lfname} \${user}@\${host}:\${rfname}

} elseif { "\$type" == "scp_get" } {
	# 从远程拷贝到本地
	spawn scp -v -r -p -C -P \${port} \${user}@\${host}:\${rfname} \${lfname}

} elseif { "\$type" == "rsync_put" } {
	# 注：使用 rsync 时，两端都需要安装 rsync

	# rsync 默认使用 SSH 进行远程登录和数据传输
	# \$ rsync [OPTION]... SRC [SRC]... [USER@]HOST:DEST
	# \$ rsync [OPTION]... [USER@]HOST:SRC [DEST]
	# -a 归档模式，表示以递归方式传输文件，并保持所有属性，它等同于-r、-l、-p、-t、-g、-o、-D 选项。-a 选项后面可以跟一个 --no-OPTION，表示关闭 -r、-l、-p、-t、-g、-o、-D 中的某一个，比如-a --no-l 等同于 -r、-p、-t、-g、-o、-D 选项。
	# -r 以递归模式处理子目录，它主要是针对目录来说的，如果单独传一个文件不需要加 -r 选项，但是传输目录时必须加。
	# -v 打印一些信息，比如文件列表、文件数量等。
	# -l 保留软连接。
	# -L 像对待常规文件一样处理软连接。如果是 SRC 中有软连接文件，则加上该选项后，将会把软连接指向的目标文件复制到 DEST。
	# -p 保持文件权限。
	# -t 保持文件时间信息。
	# -g 保持文件属组信息。
	# -o 保持文件属主信息。
	# -D 保持设备文件信息。
	# --port=PORT specify double-colon alternate port number.
	# --delete 删除 DEST 中 SRC 没有的文件。
	# --exclude=PATTERN 指定排除不需要传输的文件，等号后面跟文件名，可以是通配符模式（如 *.txt）。
	# --progress 在同步的过程中可以看到同步的过程状态，比如统计要同步的文件数量、 同步的文件传输速度等。
	# -u 把 DEST 中比 SRC 还新的文件排除掉，不会覆盖。
	# -z 压缩传输。
	# --rsh=COMMAND, -e specify the remote shell to use
	
	# 从本地拷贝到远程
	#spawn rsync -avz --delete --progress \${lfname} \${user}@\${host}:\${rfname}
	# https://www.linuxquestions.org/questions/linux-software-2/rsync-ssh-on-different-port-448112/
	spawn rsync -avz --delete --progress -e "ssh -p \${port}" \${lfname} \${user}@\${host}:\${rfname}

} elseif { "\$type" == "rsync_get" } {
	# 从远程拷贝到本地
	spawn rsync -avz --delete --progress -e "ssh -p \${port}" \${user}@\${host}:\${rfname} \${lfname} 

} else {
	puts "unknown type: ${type}\n"
	exit 1
}

expect {
	"*yes/no*" { send "yes\r"; exp_continue }
	#"*assword:*" { send "\${passwd}\r" }
	"*assword:*" { send "\${passwd}\n" }
}

interact
EOF

	# server
	svr=$(sed -n "${id}p" $svrconfname)
	#echo svr $svr
	
	# arr
	arr=($(ConvStrToArrFunc "$svr"))
	
	# 服务器信息
	host=${arr[0]}
	port=${arr[1]}
	user=${arr[2]}
	passwd=${arr[3]}
	
	# expect
	expect ${sfname} "${type}" "${host}" "${port}" "${user}" "${passwd}" "${lfname}" "${rfname}"
	
	return $CodeNormal
}

# put | get
function PutGetFunc(){
	type=$1
	
	arr=($(ConvStrToArrFunc "$2"))
	
	# 校验参数个数
	len=${#arr[@]}
	if [ $len -ne 4 ]; then
		return $CodeParamNumNotMatch
	fi
	
	# id
	id=${arr[0]}
	
	# put | get 类型
	pgtype=${arr[1]}
	
	# fname
	fname1=${arr[2]}
	fname2=${arr[3]}
	if [[ $fname1 == "" ]] || [[ $fname2 == "" ]]; then
		return $CodeInvalidParam
	fi
		
	# put {local_file_name} {remote_file_name}
	# 从本地拷贝到远程
	if [[ $pgtype == 'put' ]]; then
		# local file name
		lfname=$fname1
		# remote file name
		rfname=$fname2
		
	# get {remote_file_name} {local_file_name}
	# 从远程拷贝到本地
	elif [[ $pgtype == 'get' ]]; then
		# local file name
		lfname=$fname2
		# remote file name
		rfname=$fname1
		
	else
		printf '%s: command not found\n' "${pgtype}"
		return $CodeNormal
	fi
	
	type=${type}_${pgtype}
	ExecSFFunc "$type" "$id" "$lfname" "$rfname"
	return $?
}

# pwd
function PwdFunc(){
	printf 'cdir\t: %s\n' "${cdir}"
	printf 'fdir\t: %s\n' "${fdir}"
	printf 'ddir\t: %s\n' "${ddir}"
	return $CodeNormal
}

# 当前时间
function NowFunc(){
	echo `date "+%Y-%m-%d %H:%M:%S.%N"`
}

# ls Help
function LsHelpFunc(){
	printf '  %s\t%s\n' 'ls' 'server list'
	printf '  \t%s\n' 'Usage: ls'
}

# add Help
function AddHelpFunc(){
	printf '  %s\t%s\n' 'add' 'add server'
	printf '  \t%s\n' 'Usage: add {host} {port} {user} {passwd} {rem}'
}

# del Help
function DelHelpFunc(){
	printf '  %s\t%s\n' 'del' 'delete server'
	printf '  \t%s\n' 'Usage: del {id}'
}

# upd Help
function UpdHelpFunc(){
	printf '  %s\t%s\n' 'upd' 'update server'
	printf '  \t%s\t%s\n' 'Usage: upd {id} [-h {host}] [-P {port}] [-u {user}] [-p {passwd}] [-r {rem}]'
	printf '  \t%s\t%s\n' '-h' 'host'
	printf '  \t%s\t%s\n' '-P' 'port'
	printf '  \t%s\t%s\n' '-u' 'user'
	printf '  \t%s\t%s\n' '-p' 'passwd'
	printf '  \t%s\t%s\n' '-r' 'rem'
}

# qry Help
function QryHelpFunc(){
	printf '  %s\t%s\n' 'qry' 'query server'
	printf '  \t%s\n' 'Usage: qry {id}'
}

# ssh Help
function SshHelpFunc(){
	printf '  %s\t%s\n' 'ssh' ''
	printf '  \t%s\t%s\n' 'Usage: ssh {id}'
}

# sftp Help
function SftpHelpFunc(){
	printf '  %s\t%s\n' 'sftp' ''
	printf '  \t%s\t%s\n' 'Usage: sftp {id}'
}

# scp Help
function ScpHelpFunc(){
	printf '  %s\t%s\n' 'scp' ''
	printf '  \t%s\t%s\n' 'Usage: scp {id} put {local_file_name} {remote_file_name}'
	printf '  \t%s\t%s\n' 'Usage: scp {id} get {remote_file_name} {local_file_name}'
}

# rsync Help
function RsyncHelpFunc(){
	printf '  %s\t%s\n' 'rsync' ''
	printf '  \t%s\t%s\n' 'Usage: rsync {id} put {local_file_name} {remote_file_name}'
	printf '  \t%s\t%s\n' 'Usage: rsync {id} get {remote_file_name} {local_file_name}'
}

# pwd Help
function PwdHelpFunc(){
	printf '  %s\t%s\n' 'pwd' 'Print the name of the current working directory'
	printf '  \t%s\t%s\n' 'Usage: pwd'
}

# now Help
function NowHelpFunc(){
	printf '  %s\t%s\n' 'now' 'current time'
	printf '  \t%s\t%s\n' 'Usage: now'
}

# q Help
function QHelpFunc(){
	printf '  %s\t%s\n' 'q' 'quit'
	printf '  \t%s\n' 'Usage: q'
}

# Help
function HelpFunc(){
	LsHelpFunc
	AddHelpFunc
	DelHelpFunc
	UpdHelpFunc
	QryHelpFunc
	SshHelpFunc
	SftpHelpFunc
	ScpHelpFunc
	RsyncHelpFunc
	PwdHelpFunc
	NowHelpFunc
	QHelpFunc
}

ListFunc

# while
while true; do
	printf '\n'
	read -p 'sf-terminal$ ' p
	#echo $p	
	if [[ "$p" == '' ]]; then
		continue
	
	# 帮助命令
	elif [[ "$p" == 'h' ]]; then
		HelpFunc
		continue
	
	# ls
	elif [[ "$p" == 'ls' ]]; then
		ListFunc
		continue
	
	# add
	elif [[ "$p" == 'add' ]]; then
		AddHelpFunc
		continue
	elif [[ "$p" == 'add '* ]]; then
		AddFunc "${p: 4}"
		PrintCodeMsg $?
		continue
	
	# del
	elif [[ "$p" == 'del' ]]; then
		DelHelpFunc
		continue
	elif [[ "$p" == 'del '* ]]; then
		DelFunc "${p: 4}"
		PrintCodeMsg $?
		continue
	
	# upd
	elif [[ "$p" == 'upd' ]]; then
		UpdHelpFunc
		continue
	elif [[ "$p" == 'upd '* ]]; then
		UpdFunc "${p: 4}"
		PrintCodeMsg $?
		continue
	
	# qry
	elif [[ "$p" == 'qry' ]]; then
		QryHelpFunc
		continue
	elif [[ "$p" == 'qry '* ]]; then
		QryFunc "${p: 4}"
		PrintCodeMsg $?
		continue
	
	# ssh
	elif [[ "$p" == 'ssh' ]]; then
		SshHelpFunc
		continue
	elif [[ "$p" == 'ssh '* ]]; then
		ExecSFFunc 'ssh' "${p: 4}"
		PrintCodeMsg $?
		continue
	
	# sftp
	elif [[ "$p" == 'sftp' ]]; then
		SftpHelpFunc
		continue
	elif [[ "$p" == 'sftp '* ]]; then
		ExecSFFunc 'sftp' "${p: 5}"
		PrintCodeMsg $?
		continue
	
	# scp
	elif [[ "$p" == 'scp' ]]; then
		ScpHelpFunc
		continue
	elif [[ "$p" == 'scp '* ]]; then
		PutGetFunc 'scp' "${p: 4}"
		PrintCodeMsg $?
		continue
	
	# rsync
	elif [[ "$p" == 'rsync' ]]; then
		RsyncHelpFunc
		continue
	elif [[ "$p" == 'rsync '* ]]; then
		PutGetFunc 'rsync' "${p: 6}"
		PrintCodeMsg $?
		continue
	
	# pwd
	elif [[ "$p" == 'pwd' ]]; then
		PwdFunc
		PrintCodeMsg $?
		continue
		
	# 当前时间
	elif [[ "$p" == 'now' ]]; then
		NowFunc
		continue
	
	# quit
	elif [[ "$p" == 'q' ]]; then
		break
	
	# command not found
	else
		printf "%s: command not found\n" "${p}"
		continue
	fi
done

exit 0