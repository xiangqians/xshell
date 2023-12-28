#!/bin/bash

echo '################################################'
echo '#                                              #'
echo '# ssh, sftp, scp, rsync terminal               #'
echo '#                                              #'
echo '# Auth  : xiangqian                            #'
echo '# Date  : 18:39 ‎2023‎/0‎1‎/‎17                     #‎'
echo '# GitHub: https://github.com/xiangqians/xshell #'
echo '################################################'

# 双引号会先解析变量的内容
# 单引号包裹的内容表示原样输出

# 使用local关键字来定义局部变量，它只在函数内部有效，在函数外部无法访问该变量

# xshell.sh实际文件路径
# 使用realpath命令获取文件的绝对路径
XSHELL_FILE=$(realpath $(ls -al $0 | awk '{print $NF}'))
# 判断是否是软链接文件
if [[ -h "$0" ]]; then
	XSHELL_LN_FILE=$(realpath -s $0)
	echo -e 'XShell  File\t : '${XSHELL_LN_FILE}' -> '${XSHELL_FILE}
else
	echo -e 'XShell  File\t : '${XSHELL_FILE}
fi

# 获取xshell.sh文件所在的目录
XSHELL_FILE_DIR=${XSHELL_FILE%/*}

# 服务器配置文件
SERVER_CONF_FILE="${XSHELL_FILE_DIR}/server.conf"
echo -e "Server  Conf File: ${SERVER_CONF_FILE}"

# 定义一个空map，存储服务器配置信息
declare -A server=()

# 清空map
function clear_map(){
	for key in ${!server[@]}; do
		unset server[$key]
	done
}

# 读取服务配置文件
function read_server_conf_func(){
	# 目标id
	local target_id=$1
	
	# 回调函数
	local callback_func=$2

	# 服务器id
	local id=1
	
	# 清空map
	clear_map
	
	# 逐行读取文件内容
	# read命令读取文件时会自动去掉行前后的空格
	# IFS=用于禁用行分隔符
	# -r参数用于禁止对反斜杠进行转义
	# || [[ -n "$line" ]]的作用是保证在读取到最后一行时，循环仍然能够继续执行
	while IFS= read -r line || [[ -n "$line" ]]; do
		# 去除字符串前后空格
		line="${line#"${line%%[![:space:]]*}"}"
		line="${line%"${line##*[![:space:]]}"}"
		#echo '"'$line'"'
		
		# id
		if [[ $line == '-' ]]; then
			local host=${server['host']}
			if [[ "$host" != '' ]]; then
				server['id']=$id
				$callback_func
				if [[ "$id" == "$target_id" ]]; then
					return 1
				fi
				clear_map
				let id++
			fi
		
		# host
		elif [[ $line =~ ^host: ]]; then
			local host=${line:5}
			host="${host#"${host%%[![:space:]]*}"}"
			host="${host%"${host##*[![:space:]]}"}"
			server['host']=$host
		
		# port
		elif [[ $line =~ ^port: ]]; then
			local port=${line:5}
			port="${port#"${port%%[![:space:]]*}"}"
			port="${port%"${port##*[![:space:]]}"}"
			server['port']=$port
			
		# user
		elif [[ $line =~ ^user: ]]; then
			local user=${line:5}
			user="${user#"${user%%[![:space:]]*}"}"
			user="${user%"${user##*[![:space:]]}"}"
			server['user']=$user
		
		# passwd
		elif [[ $line =~ ^passwd: ]]; then
			local passwd=${line:7}
			passwd="${passwd#"${passwd%%[![:space:]]*}"}"
			passwd="${passwd%"${passwd##*[![:space:]]}"}"
			server['passwd']=$passwd
		
		# key-file
		elif [[ $line =~ ^key-file: ]]; then
			local key_file=${line:9}
			key_file="${key_file#"${key_file%%[![:space:]]*}"}"
			key_file="${key_file%"${key_file##*[![:space:]]}"}"
			server['key_file']=$key_file
		
		# rem
		elif [[ $line =~ ^rem: ]]; then
			local rem=${line:4}
			rem="${rem#"${rem%%[![:space:]]*}"}"
			rem="${rem%"${rem##*[![:space:]]}"}"
			server['rem']=$rem
		fi
	done < ${SERVER_CONF_FILE}
	
	local host=${server['host']}
	if [[ "$host" != '' ]]; then
		server['id']=$id
		$callback_func
		if [[ "$id" == "$target_id" ]]; then
			return 1
		fi
	fi
	clear_map
	
	return 0
}

# 服务器列表命令帮助
function ls_help_func(){
	printf '  %s\t%s\n' 'ls' 'server list'
	printf '  \t%s\n' 'Usage: ls'
}

# 打印格式化
FORMAT='%-5s %-20s %-10s %-20s %-16s %s\n'

# 服务器列表回调函数
function ls_callback_func(){	
	#echo server ${server[@]}
	
	local id=${server['id']}
	local host=${server['host']}
	local port=${server['port']}
	local user=${server['user']}
	local passwd=${server['passwd']}
	local key_file=${server['key_file']}
	local rem=${server['rem']}
	
	printf "${FORMAT}" "${id}" "${host}" "${port}" "${user}" "******" "${rem}"
	
	return 0
}

# 服务器列表
function ls_func(){
	printf "${FORMAT}" 'ID' 'HOST' 'PORT' 'USER' 'PASSWD/KEY-FILE' 'REM'
	read_server_conf_func 0 ls_callback_func
}

# 获取服务器信息命令帮助
function get_help_func(){
	printf '  %s\t%s\n' 'get' 'get server'
	printf '  \t%s\n' 'Usage: get {id}'
}

# 获取服务器信息
function get_func(){
	if [[ $# -eq 0 ]]; then
		get_help_func
		return
	fi
	
	if [[ $# -ne 1 ]]; then
		printf 'invalid parameter\n'
		return
	fi
	
	local id=$1
	read_server_conf_func "$id"
	local result=$?
	if [[ $result -eq 0 ]]; then
		printf 'invalid id\n'
		return
	fi
	
	local host=${server['host']}
	local port=${server['port']}
	local user=${server['user']}
	local passwd=${server['passwd']}
	local key_file=${server['key_file']}
	local rem=${server['rem']}
	
	printf 'Host\t: %s\n' "${host}"
	printf 'Port\t: %s\n' "${port}"
	printf 'User\t: %s\n' "${user}"
	printf 'Passwd\t: %s\n' "${passwd}"
	printf 'Key File: %s\n' "${key_file}"
	printf 'Rem\t: %s\n' "${rem}"
}

# ssh命令帮助
function ssh_help_func(){
	printf '  %s\n' 'ssh'
	printf '  \t%s\n' 'Usage: ssh {id}'
}

# ssh命令
function ssh_func(){
	if [[ $# -eq 0 ]]; then
		ssh_help_func
		return
	fi
	
	if [[ $# -ne 1 ]]; then
		printf 'invalid parameter\n'
		return
	fi
	
	local id=$1
	read_server_conf_func "$id"
	local result=$?
	if [[ $result -eq 0 ]]; then
		printf 'invalid id\n'
		return
	fi
	
	local host=${server['host']}
	local port=${server['port']}
	local user=${server['user']}
	local passwd=${server['passwd']}
	local key_file=${server['key_file']}

	# 使用expect自动登录远程服务器
	expect -c "
	# 设置超时时间，60s
	#set timeout -1
	set timeout 60
	
	# spawn：启动一个新的进程，并将其与当前进程进行交互
	spawn ssh ${user}@${host} -p ${port}
	
	# expect：等待特定的字符串或正则表达式出现，并执行相应的操作
	expect {
		# send：向进程发送字符串，并将该参数发送到进程，这个过程类似模拟人类交互
		# exp_continue：允许expect继续向下执行指令，在expect中多次匹配就需要用到
		\"*yes/no*\" { send \"yes\r\"; exp_continue }
		\"*assword:*\" { send \"${passwd}\r\" }
	}
	
	# interact：允许用户与进程进行交互，interact命令可以在适当的时候进行任务的干预，
	# 比如下载完ftp文件时，仍然可以停留在ftp命令行状态，以便手动的执行后续命令
	interact
	"
}

# sftp命令帮助
function sftp_help_func(){
	printf '  %s\n' 'sftp'
	printf '  \t%s\n' 'Usage: sftp {id}'
}

# sftp命令
function sftp_func(){
	if [[ $# -eq 0 ]]; then
		sftp_help_func
		return
	fi
	
	if [[ $# -ne 1 ]]; then
		printf 'invalid parameter\n'
		return
	fi
	
	local id=$1
	read_server_conf_func "$id"
	local result=$?
	if [[ $result -eq 0 ]]; then
		printf 'invalid id\n'
		return
	fi
	
	local host=${server['host']}
	local port=${server['port']}
	local user=${server['user']}
	local passwd=${server['passwd']}
	local key_file=${server['key_file']}

	expect -c "
	set timeout 60
	spawn sftp -P ${port} ${user}@${host}
	expect {
		\"*yes/no*\" { send \"yes\r\"; exp_continue }
		\"*assword:*\" { send \"${passwd}\n\" }
	}
	interact
	"
}

# scp命令帮助
function scp_help_func(){
	printf '  %s\n' 'scp'
	printf '  \t%s\n' 'Usage: '
	printf '  \t%s\n' 'scp {id} put {local file} {remote file}'
	printf '  \t%s\n' 'scp {id} get {remote file} {local file}'
}

# scp命令
function scp_func(){
	if [[ $# -eq 0 ]]; then
		scp_help_func
		return
	fi
	
	if [[ $# -ne 4 ]]; then
		printf 'invalid parameter\n'
		return
	fi
	
	local id=$1
	read_server_conf_func "$id"
	local result=$?
	if [[ $result -eq 0 ]]; then
		printf 'invalid id\n'
		return
	fi
	
	local host=${server['host']}
	local port=${server['port']}
	local user=${server['user']}
	local passwd=${server['passwd']}
	local key_file=${server['key_file']}
	
	if [[ "$2" == 'put' ]]; then
		local local_file=$3
		local remote_file=$4
		expect -c "
		set timeout 60
		
		# scp（secure copy）是一个基于 SSH 协议在网络之间进行安全传输的命令
		# -v 输出详细信息
		# -r 递归复制目录及其内容
		# -p 保留文件的访问和修改时间
		# -C 在复制过程中压缩文件或目录
		# -6 使用 IPv6 协议
		# -i 指定身份验证文件（例如私钥文件）
		# -P 指定远程主机的 sshd 端口号
		
		# 从本地复制文件到远程主机
		spawn scp -v -r -p -C -P ${port} ${local_file} ${user}@${host}:${remote_file}
		
		expect {
			\"*yes/no*\" { send \"yes\r\"; exp_continue }
			\"*assword:*\" { send \"${passwd}\n\" }
		}
		interact
		"
		
	elif [[ "$2" == 'get' ]]; then
		local remote_file=$3
		local local_file=$4
		expect -c "
		set timeout 60
		
		# 从远程主机复制文件到本地
		spawn scp -v -r -p -C -P ${port} ${user}@${host}:${remote_file} ${local_file}
		
		expect {
			\"*yes/no*\" { send \"yes\r\"; exp_continue }
			\"*assword:*\" { send \"${passwd}\n\" }
		}
		interact
		"
		
	else
		printf 'invalid operation\n'
	fi
}

# rsync命令帮助
function rsync_help_func(){
	printf '  %s\t\n' 'rsync'
	printf '  \t%s\n' 'Usage: '
	printf '  \t%s\n' 'rsync {id} put {local file} {remote file}'
	printf '  \t%s\n' 'rsync {id} get {remote file} {local file}'
}

# rsync命令
function rsync_func(){
	if [[ $# -eq 0 ]]; then
		rsync_help_func
		return
	fi
	
	if [[ $# -ne 4 ]]; then
		printf 'invalid parameter\n'
		return
	fi
	
	local id=$1
	read_server_conf_func "$id"
	local result=$?
	if [[ $result -eq 0 ]]; then
		printf 'invalid id\n'
		return
	fi
	
	local host=${server['host']}
	local port=${server['port']}
	local user=${server['user']}
	local passwd=${server['passwd']}
	local key_file=${server['key_file']}
	
	if [[ "$2" == 'put' ]]; then
		local local_file=$3
		local remote_file=$4
		expect -c "
		set timeout 60
		
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
		
		# 从本地复制文件到远程主机
		#spawn rsync -avz --delete --progress ${local_file} ${user}@${host}:${remote_file}
		# https://www.linuxquestions.org/questions/linux-software-2/rsync-ssh-on-different-port-448112/
		spawn rsync -avz --delete --progress -e \"ssh -p ${port}\" ${local_file} ${user}@${host}:${remote_file}
		
		expect {
			\"*yes/no*\" { send \"yes\r\"; exp_continue }
			\"*assword:*\" { send \"${passwd}\n\" }
		}
		interact
		"
		
	elif [[ "$2" == 'get' ]]; then
		local remote_file=$3
		local local_file=$4
		expect -c "
		set timeout 60

		# 从远程主机复制文件到本地
		spawn rsync -avz --delete --progress -e \"ssh -p ${port}\" ${user}@${host}:${remote_file} ${local_file} 

		expect {
			\"*yes/no*\" { send \"yes\r\"; exp_continue }
			\"*assword:*\" { send \"${passwd}\n\" }
		}
		interact
		"
		
	else
		printf 'invalid operation\n'
	fi
}

# quit命令帮助
function quit_help_func(){
	printf '  %s\t%s\n' 'quit' 'quit'
	printf '  \t%s\n' 'Usage: quit'
}

# 命令帮助
function help_func(){
	ls_help_func
	get_help_func
	ssh_help_func
	sftp_help_func
	scp_help_func
	rsync_help_func
	quit_help_func
}

echo ''
ls_func

while true; do
	printf '\n'
	# -p prompt（提示字符串）
	read -p 'xshell$ ' cmd parameters_str
	if [[ "$cmd" == '' ]]; then
		continue
	fi
	
	#echo cmd $cmd
	#echo parameters_str $parameters_str

	parameters=()
	index=0
	
	while true; do
		# 去除字符串前后空格
		parameters_str="${parameters_str#"${parameters_str%%[![:space:]]*}"}"
		parameters_str="${parameters_str%"${parameters_str##*[![:space:]]}"}"
		
		# ${parameters_str%%pattern*}: 删除从 parameters_str 开头开始匹配的最长的 pattern*
		# [[:space:]]: 匹配任何一个空白字符
		# 例如，如果str的值为"This is a sample string"，那么${parameters_str%%[[:space:]]*}将返回"This"，即删除了第一个空格及其后的所有字符
		
		parameters_substr=
		
		# 判断字符串是否以 双引号 开头
		if [[ "$parameters_str" == '"'* ]]; then
			parameters_str=${parameters_str:1}
			parameters_substr=${parameters_str%%\"[[:space:]]*}
			if [[ "$parameters_str" == "$parameters_substr" ]]; then
				parameters_substr=${parameters_str%%\"*}
				parameters_str=
			else
				len=${#parameters_substr}
				let len=len+2
				parameters_str=${parameters_str:${len}}
			fi
		
		# 空格分隔
		else
			parameters_substr=${parameters_str%%[[:space:]]*}
			len=${#parameters_substr}
			let len=len+1
			parameters_str=${parameters_str:${len}}
		fi
		if [[ $parameters_substr == '' ]]; then
			break
		fi
		
		#echo $index $parameters_substr '('$parameters_str')'
		parameters[$index]=$parameters_substr
		let index++
	done
	
	#echo parameters ${#parameters[@]} ${parameters[@]}
	
	# ls
	if [[ "$cmd" == 'ls' ]]; then
		ls_func
	
	# get
	elif [[ "$cmd" == 'get' ]]; then
		get_func "${parameters[@]}"
	
	# ssh
	elif [[ "$cmd" == 'ssh' ]]; then
		ssh_func "${parameters[@]}"
	
	# sftp
	elif [[ "$cmd" == 'sftp' ]]; then
		sftp_func "${parameters[@]}"
	
	# scp
	elif [[ "$cmd" == 'scp' ]]; then
		scp_func "${parameters[@]}"
	
	# rsync
	elif [[ "$cmd" == 'rsync' ]]; then
		rsync_func "${parameters[@]}"
	
	# quit
	elif [[ "$cmd" == 'quit' ]]; then
		break
	
	# help
	elif [[ "$cmd" == 'help' ]]; then
		help_func
	
	# command not found
	else
		printf "%s: command not found\n" "${cmd}"
	fi
done

exit 0