#!/bin/bash

cat << EOF
################################################
#                                              #
# SSH, SFTP, SCP, RSYNC                        #
#                                              #
# Auth  : xiangqian                            #
# Date  : 18:39 ‎2023‎/0‎1‎/‎17                     #‎
# GitHub: https://github.com/xiangqians/xshell #
################################################
EOF


# 双引号会先解析变量的内容
# 单引号包裹的内容表示原样输出


# 获取 xshell.sh 文件的真实路径
xshell_file=$(realpath $(ls -al $0 | awk '{print $NF}'))
# 判断 xshell.sh 是否是软链接文件
if [[ -h "$0" ]]; then
	local xshell_ln_file=$(realpath -s $0)
	echo 'XShell File: '${xshell_ln_file}' -> '${xshell_file}
else
	echo 'XShell File: '${xshell_file}
fi


# 获取 xshell.sh 文件所在的目录
xshell_dir=${xshell_file%/*}


# 服务器配置文件
server_file="${xshell_dir}/server.yaml"
echo "Server File: ${server_file}"
echo ''


#exit 0


# 声明关联数组，用来存储服务器配置信息
# 'declare'：声明变量
# '-A'：指定是一个关联数组
# 注：Bash 4.0+ 才支持关联数组。查看 Bash 版本：$ bash --version
declare -A servers

# 声明整数变量，用于存储服务器数量
declare -i count=0

declare host=''
declare port=''
declare user=''
declare passwd=''
declare key_file=''
declare rem=''

declare -i id_width=2
declare -i host_width=4
declare -i port_width=4 
declare -i user_width=4
declare -i passwd_or_key_file_width=15
declare -i rem_width=3

init() {
	# 使用文件描述符读取服务器配置文件内容
	# 使用文件描述符可以避免重复打开和关闭文件，尤其是在循环读取文件内容时，可以显著提高效率。
	# 文件描述符一旦打开，可以在整个脚本或程序执行期间保持打开状态，直到显式关闭为止。

	# 打开文件描述符
	# 将文件关联到文件描述符 3 上，使得 read 命令可以从文件描述符 3 中读取数据，而不是直接从文件中读取。
	exec 3< "${server_file}"
	
	local id=0

	# 逐行读取文件内容
	while IFS= read -r -u 3 line; do
		# ':0:1'：表示截取变量值从索引等于0开始，截取长度为 1
		if [[ "${line:0:1}" == "-" ]]; then
			let id++
			
			line=" ${line:1}"
			
			local id_str="${id}"
			local length=${#id_str}
			if [[ ${length} -gt ${id_width} ]]; then
				id_width=${length}
			fi
		fi
		
		local prefix=
		local length=
		
		prefix='  host:'
		length=${#prefix}
		if [[ "${line:0:${length}}" == "${prefix}" ]]; then
			local host="${line:${length}}"
			
			# 去除字符串前后空格
			host="${host#"${host%%[![:space:]]*}"}"
			host="${host%"${host##*[![:space:]]}"}"
			
			servers["${id},host"]="${host}"
			
			local length=${#host}
			if [[ ${length} -gt ${host_width} ]]; then
				host_width=${length}
			fi
			
			continue
		fi
		
		prefix='  port:'
		length=${#prefix}
		if [[ "${line:0:${length}}" == "${prefix}" ]]; then
			local port="${line:${length}}"
			port="${port#"${port%%[![:space:]]*}"}"
			port="${port%"${port##*[![:space:]]}"}"
			servers["${id},port"]="${port}"
			
			local length=${#port}
			if [[ ${length} -gt ${port_width} ]]; then
				port_width=${length}
			fi
			
			continue
		fi
		
		prefix='  user:'
		length=${#prefix}
		if [[ "${line:0:${length}}" == "${prefix}" ]]; then
			local user="${line:${length}}"
			user="${user#"${user%%[![:space:]]*}"}"
			user="${user%"${user##*[![:space:]]}"}"
			servers["${id},user"]="${user}"
			
			local length=${#user}
			if [[ ${length} -gt ${user_width} ]]; then
				user_width=${length}
			fi
			
			continue
		fi
		
		prefix='  passwd:'
		length=${#prefix}
		if [[ "${line:0:${length}}" == "${prefix}" ]]; then
			local passwd="${line:${length}}"
			passwd="${passwd#"${passwd%%[![:space:]]*}"}"
			passwd="${passwd%"${passwd##*[![:space:]]}"}"
			servers["${id},passwd"]="${passwd}"
			continue
		fi
		
		prefix='  key-file:'
		length=${#prefix}
		if [[ "${line:0:${length}}" == "${prefix}" ]]; then
			local key_file="${line:${length}}"
			key_file="${key_file#"${key_file%%[![:space:]]*}"}"
			key_file="${key_file%"${key_file##*[![:space:]]}"}"
			servers["${id},key-file"]="${key_file}"
			continue
		fi
		
		prefix='  rem:'
		length=${#prefix}
		if [[ "${line:0:${length}}" == "${prefix}" ]]; then
			local rem="${line:${length}}"
			rem="${rem#"${rem%%[![:space:]]*}"}"
			rem="${rem%"${rem##*[![:space:]]}"}"
			servers["${id},rem"]="${rem}"
			
			local length=${#rem}
			if [[ ${length} -gt ${rem_width} ]]; then
				rem_width=${length}
			fi
			
			continue
		fi
	done
	
	count=id
	
	# 关闭文件描述符
	# 关闭文件描述符 3，释放与文件的关联。
	exec 3<&-
}

init

get_server() {
	local id=$1
	
	host=${servers["${id},host"]}
	if [[ "${host}" == '' ]]; then
		# 服务器信息不存在
		return 1
	fi
	
	port=${servers["${id},port"]}
	user=${servers["${id},user"]}
	passwd=${servers["${id},passwd"]}
	key_file=${servers["${id},key-file"]}
	rem=${servers["${id},rem"]}
	
	return 0
}


# 服务器列表命令帮助
_ls_help() {
	printf '  %s\t%s\n' 'ls' 'Server List'
	printf '  \t%s\n' 'Usage: ls'
}

#_ls_help
#exit 0

# 生成分隔线
generate_separator() {
    local length=$1
    local separator=""
	local i=0
    for (( ; i < length; i++)); do
        separator+="-"
    done
    echo "${separator}"
}

test_generate_separator() {
	local separator=$(generate_separator 2)
	echo "separator=${separator}"
	exit 0
}

#test_generate_separator

# 服务器列表
_ls() {
	# 格式化
	local format="%-${id_width}s  %-${host_width}s  %-${port_width}s  %-${user_width}s  %-${passwd_or_key_file_width}s  %s\n"
	
	# 打印表头
	printf "${format}" 'ID' 'HOST' 'PORT' 'USER' 'PASSWD/KEY-FILE' 'REM'
	
	# 打印分隔线
	printf "${format}" "$(generate_separator ${id_width})" "$(generate_separator ${host_width})" "$(generate_separator ${port_width})" "$(generate_separator ${user_width})" "$(generate_separator ${passwd_or_key_file_width})" "$(generate_separator ${rem_width})"
	
	# 使用 for 循环遍历 server_count 变量
	for (( id=1; id<=${count}; id++ )); do
		if get_server "${id}"; then
			printf "${format}" "${id}" "${host}" "${port}" "${user}" '******' "${rem}"
		fi
	done
}

#_ls
#exit 0


# 获取服务器信息命令帮助
_get_help() {
	printf '  %s\t%s\n' 'get' 'Get Server'
	printf '  \t%s\n' 'Usage: get {id}'
}

# 获取服务器信息
_get() {
	# 参数
	local args=("$@")
	local length=${#args[@]}
	
	# 如果参数个数等于 0 时
	if [[ length -eq 0 ]]; then
		_get_help
		return
	fi
	
	# 如果参数个数不等于 1 时
	if [[ length -ne 1 ]]; then
		printf 'invalid parameter\n'
		return
	fi
	
	# id
	# 获取数组的第一个元素
	local id="${args[0]}"
	
	# 如果 id 不是正整数时
	if ! [[ ${id} =~ ^[1-9][0-9]*$ ]]; then
		printf 'invalid id\n'
		return
	fi
	
	if ! get_server "${id}"; then
		printf "%s: id not found\n" "${id}"
		return
	fi
	
	printf 'Host\t: %s\n' "${host}"
	printf 'Port\t: %s\n' "${port}"
	printf 'User\t: %s\n' "${user}"
	printf 'Passwd\t: %s\n' "${passwd}"
	printf 'Key File: %s\n' "${key_file}"
	printf 'Rem\t: %s\n' "${rem}"
}


# ssh命令帮助
_ssh_help() {
	printf '  %s\t%s\n' 'ssh' 'Secure Shell'
	printf '  \t%s\n' 'Usage: ssh {id}'
}

# ssh命令
_ssh() {
	# 参数
	local args=("$@")
	local length=${#args[@]}
	
	# 如果参数个数等于 0 时
	if [[ length -eq 0 ]]; then
		_ssh_help
		return
	fi
	
	# 如果参数个数不等于 1 时
	if [[ length -ne 1 ]]; then
		printf 'invalid parameter\n'
		return
	fi
	
	# id
	# 获取数组的第一个元素
	local id="${args[0]}"
	
	# 如果 id 不是正整数时
	if ! [[ ${id} =~ ^[1-9][0-9]*$ ]]; then
		printf 'invalid id\n'
		return
	fi
	
	if ! get_server "${id}"; then
		printf "%s: id not found\n" "${id}"
		return
	fi

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
_sftp_help() {
	printf '  %s\t%s\n' 'sftp' 'SSH File Transfer Protocol'
	printf '  \t%s\n' 'Usage: sftp {id}'
}

# sftp命令
_sftp() {
	# 参数
	local args=("$@")
	local length=${#args[@]}
	
	# 如果参数个数等于 0 时
	if [[ length -eq 0 ]]; then
		_sftp_help
		return
	fi
	
	# 如果参数个数不等于 1 时
	if [[ length -ne 1 ]]; then
		printf 'invalid parameter\n'
		return
	fi
	
	# id
	# 获取数组的第一个元素
	local id="${args[0]}"
	
	# 如果 id 不是正整数时
	if ! [[ ${id} =~ ^[1-9][0-9]*$ ]]; then
		printf 'invalid id\n'
		return
	fi
	
	if ! get_server "${id}"; then
		printf "%s: id not found\n" "${id}"
		return
	fi
	
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
_scp_help() {
	printf '  %s\t%s\n' 'scp' 'Secure Copy Protocol'
	printf '  \t%s\n' 'Usage: '
	printf '  \t%s\n' 'scp {id} put {local file} {remote file}'
	printf '  \t%s\n' 'scp {id} get {remote file} {local file}'
}

# scp命令
_scp() {
	# 参数
	local args=("$@")
	local length=${#args[@]}
	
	# 如果参数个数等于 0 时
	if [[ length -eq 0 ]]; then
		_scp_help
		return
	fi
	
	# 如果参数个数不等于 4 时
	if [[ length -ne 4 ]]; then
		printf 'invalid parameter\n'
		return
	fi
	
	# id
	local id="${args[0]}"
	
	# 如果 id 不是正整数时
	if ! [[ ${id} =~ ^[1-9][0-9]*$ ]]; then
		printf 'invalid id\n'
		return
	fi
	
	if ! get_server "${id}"; then
		printf "%s: id not found\n" "${id}"
		return
	fi
	
	local type="${args[1]}"
	if [[ "${type}" == 'put' ]]; then
		local local_file="${args[2]}"
		local remote_file="${args[3]}"
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
		
	elif [[ "${type}" == 'get' ]]; then
		local remote_file="${args[2]}"
		local local_file="${args[3]}"
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
_rsync_help() {
	printf '  %s\t%s\n' 'rsync' 'Remote Sync'
	printf '  \t%s\n' 'Usage: '
	printf '  \t%s\n' 'rsync {id} put {local file} {remote file}'
	printf '  \t%s\n' 'rsync {id} get {remote file} {local file}'
}

# rsync命令
_rsync() {
	# 参数
	local args=("$@")
	local length=${#args[@]}
	
	# 如果参数个数等于 0 时
	if [[ length -eq 0 ]]; then
		_rsync_help
		return
	fi
	
	# 如果参数个数不等于 4 时
	if [[ length -ne 4 ]]; then
		printf 'invalid parameter\n'
		return
	fi
	
	# id
	local id="${args[0]}"
	
	# 如果 id 不是正整数时
	if ! [[ ${id} =~ ^[1-9][0-9]*$ ]]; then
		printf 'invalid id\n'
		return
	fi
	
	if ! get_server "${id}"; then
		printf "%s: id not found\n" "${id}"
		return
	fi
	
	local type="${args[1]}"
	if [[ "${type}" == 'put' ]]; then
		local local_file="${args[2]}"
		local remote_file="${args[3]}"
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
		
	elif [[ "${type}" == 'get' ]]; then
		local remote_file="${args[2]}"
		local local_file="${args[3]}"
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
_quit_help() {
	printf '  %s\t%s\n' 'quit' 'Quit'
	printf '  \t%s\n' 'Usage: quit'
}


# 命令帮助
_help() {
	_ls_help
	_get_help
	_ssh_help
	_sftp_help
	_scp_help
	_rsync_help
	_quit_help
}


main() {
	# 服务器列表
	_ls
	
	# 读取用户
	while true; do
		printf '\n'
		
		# read 命令用于从标准输入（通常是键盘）读取用户输入
		# '-p "prompt"'：指定一个提示符（prompt），即在等待用户输入时显示给用户的信息
		# '-r'：表示 “raw”，作用是 read 命令在读取输入时不要对反斜杠字符进行特殊处理。当使用了 -r 选项后，read 命令会保持输入内容中反斜杠字符 \ 的原样性。通常情况下，如果没有使用 -r 选项，read 命令会将输入中的反斜杠 \ 进行转义处理，这意味着 \n 会被解释为换行符而不是两个字符 \ 和 n
		# '-e'：启用行编辑功能，允许用户在输入过程中使用光标移动（左右箭头键）、删除（Backspace键）和插入（在任意位置插入文本）等操作
		# '-a array'：将输入的参数分割存储到数组 array 中
		#read -p 'xshell$ ' -r -e -a array
		read -p 'xshell$ ' -r -e input
		
		# 使用 eval 将输入解析成数组
		eval "array=(${input})"
		
		# 数组长度
		local length=${#array[@]}
		#echo "length=${length}"
		
		# 如果数组长度为 0 时
		if [[ length -eq 0 ]]; then
			continue
		fi
		
		# 命令
		# 获取数组的第一个元素
		local cmd="${array[0]}"
		#echo "cmd=${cmd}"
		
		# 参数
		# 截取数组，从索引 1 到结尾的元素
		local args=("${array[@]:1}")
		#print_array "${args[@]}"
		
		# ls
		if [[ "$cmd" == 'ls' ]]; then
			_ls
		
		# get
		elif [[ "$cmd" == 'get' ]]; then
			_get "${args[@]}"
		
		# ssh
		elif [[ "$cmd" == 'ssh' ]]; then
			_ssh "${args[@]}"
		
		# sftp
		elif [[ "$cmd" == 'sftp' ]]; then
			_sftp "${args[@]}"
		
		# scp
		elif [[ "$cmd" == 'scp' ]]; then
			_scp "${args[@]}"
		
		# rsync
		elif [[ "$cmd" == 'rsync' ]]; then
			_rsync "${args[@]}"
		
		# quit
		elif [[ "$cmd" == 'quit' ]]; then
			break
		
		# help
		elif [[ "$cmd" == 'help' ]]; then
			_help
		
		# command not found
		else
			printf "%s: command not found\n" "${cmd}"
		fi
	done
}

main

exit 0