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


# 单引号：保留所有字符的原始含义，不进行变量替换或者转义字符解析。
# 双引号：允许变量替换和大部分转义字符的解析，除了一些特殊的字符如 $、\、` 等。


# 获取 xshell.sh 文件的真实路径
global_xshell_file=$(realpath $(ls -al $0 | awk '{print $NF}'))
# 判断 xshell.sh 是否是软链接文件
if [[ -h "$0" ]]; then
	global_xshell_ln_file=$(realpath -s $0)
	echo 'XShell  File: '${global_xshell_ln_file}' -> '${global_xshell_file}
else
	echo 'XShell  File: '${global_xshell_file}
fi

# 获取 xshell.sh 文件所在的目录
global_xshell_dir=${global_xshell_file%/*}

# 服务器配置文件
global_server_file="${global_xshell_dir}/server.yaml"
echo "Server  File: ${global_server_file}"

# 命令历史记录文件
global_history_file="${global_xshell_dir}/history"
echo "History File: ${global_history_file}"

# 命令历史记录临时文件
global_tmp_history_file="${global_xshell_dir}/tmp_history"

echo ''


# 声明关联数组，用来存储服务器信息
# 'declare'：声明变量
# '-A'：指定是一个关联数组
# 注：Bash 4.0+ 才支持关联数组。查看 Bash 版本：$ bash --version
declare -A global_servers

# 声明整数变量，用于存储服务器数量
declare -i global_count=0


# 服务器信息
declare global_host=''
declare global_port=''
declare global_user=''
declare global_passwd=''
declare global_key_file=''
declare global_rem=''


# 服务器信息字段宽度
declare -i global_id_width=2
declare -i global_host_width=4
declare -i global_port_width=4 
declare -i global_user_width=4
declare -i global_passwd_or_key_file_width=15
declare -i global_rem_width=3


# 读取服务器配置文件
read_server_file() {
	# 清空关联数组
	global_servers=()
	
	# 使用文件描述符读取服务器配置文件内容
	# 使用文件描述符可以避免重复打开和关闭文件，尤其是在循环读取文件内容时，可以显著提高效率。
	# 文件描述符一旦打开，可以在整个脚本或程序执行期间保持打开状态，直到显式关闭为止。

	# 打开文件描述符
	# 将文件关联到文件描述符 3 上，使得 read 命令可以从文件描述符 3 中读取数据，而不是直接从文件中读取。
	exec 3< "${global_server_file}"
	
	local id=0

	# 逐行读取文件内容
	# 'IFS='：IFS 是 Bash 的一个特殊变量，用于控制字段分隔符（Internal Field Separator）。在这里，'IFS=' 表示将字段分隔符设置为空，这样可以确保在读取行时不会因为空格或制表符而分割行内容，而是将整行作为一个完整的字符串。
	# '-r'：表示 “raw”，作用是 read 命令在读取输入时不要对反斜杠字符进行特殊处理。当使用了 -r 选项后，read 命令会保持输入内容中反斜杠字符 \ 的原样性。通常情况下，如果没有使用 -r 选项，read 命令会将输入中的反斜杠 \ 进行转义处理，这意味着 \n 会被解释为换行符而不是两个字符 \ 和 n
	# '-u 3'：表示从文件描述符 3 中读取输入。文件描述符是用来标识文件或其他输入输出源的整数值。
	while IFS= read -r -u 3 line; do
		# ':0:1'：表示截取变量值从索引等于 0 开始，长度为 1
		if [[ "${line:0:1}" == "-" ]]; then
			let id++
			let global_count++
			
			# ':1'：表示截取变量值从索引等于 1 开始，其后的子串
			# 将开头的 '-' 替换为 ' '（空格）
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
			
			global_servers["${id},host"]="${host}"
			
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
			global_servers["${id},port"]="${port}"
			
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
			global_servers["${id},user"]="${user}"
			
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
			global_servers["${id},passwd"]="${passwd}"
			continue
		fi
		
		prefix='  key-file:'
		length=${#prefix}
		if [[ "${line:0:${length}}" == "${prefix}" ]]; then
			local key_file="${line:${length}}"
			key_file="${key_file#"${key_file%%[![:space:]]*}"}"
			key_file="${key_file%"${key_file##*[![:space:]]}"}"
			global_servers["${id},key-file"]="${key_file}"
			continue
		fi
		
		prefix='  rem:'
		length=${#prefix}
		if [[ "${line:0:${length}}" == "${prefix}" ]]; then
			local rem="${line:${length}}"
			rem="${rem#"${rem%%[![:space:]]*}"}"
			rem="${rem%"${rem##*[![:space:]]}"}"
			global_servers["${id},rem"]="${rem}"
			
			local length=${#rem}
			if [[ ${length} -gt ${rem_width} ]]; then
				rem_width=${length}
			fi
			
			continue
		fi
	done
	
	# 关闭文件描述符
	# 关闭文件描述符 3，释放与文件的关联。
	exec 3<&-
}


get_server() {
	local id=$1
	
	global_host=${global_servers["${id},host"]}
	if [[ "${global_host}" == '' ]]; then
		# 服务器信息不存在
		return 1
	fi
	
	global_port=${global_servers["${id},port"]}
	global_user=${global_servers["${id},user"]}
	global_passwd=${global_servers["${id},passwd"]}
	global_key_file=${global_servers["${id},key-file"]}
	global_rem=${global_servers["${id},rem"]}
	
	return 0
}


# 服务器列表命令帮助
_ls_help() {
	printf '  %s\t  %s\n' 'ls' 'Server List'
	printf '  \t  %s\n' 'Usage: ls'
}

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

# 服务器列表
_ls() {
	# 参数
	local args=("$@")
	local length=${#args[@]}
	
	# 如果参数个数不等于 0 时
	if [[ length -ne 0 ]]; then
		printf 'invalid parameter\n'
		return
	fi
	
	# 格式化
	local format="%-${global_id_width}s  %-${global_host_width}s  %-${global_port_width}s  %-${global_user_width}s  %-${global_passwd_or_key_file_width}s  %s\n"
	
	# 打印表头
	printf "${format}" 'ID' 'HOST' 'PORT' 'USER' 'PASSWD/KEY-FILE' 'REM'
	
	# 打印分隔线
	printf "${format}" "$(generate_separator ${global_id_width})" "$(generate_separator ${global_host_width})" "$(generate_separator ${global_port_width})" "$(generate_separator ${global_user_width})" "$(generate_separator ${global_passwd_or_key_file_width})" "$(generate_separator ${global_rem_width})"
	
	# 使用 for 循环遍历 global_count 变量
	for (( id=1; id<=${global_count}; id++ )); do
		if get_server "${id}"; then
			printf "${format}" "${id}" "${global_host}" "${global_port}" "${global_user}" '******' "${global_rem}"
		fi
	done
}


# 获取服务器信息命令帮助
_get_help() {
	printf '  %s\t  %s\n' 'get' 'Get Server'
	printf '  \t  %s\n' 'Usage: get {id}'
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
	
	printf 'Host\t: %s\n' "${global_host}"
	printf 'Port\t: %s\n' "${global_port}"
	printf 'User\t: %s\n' "${global_user}"
	printf 'Passwd\t: %s\n' "${global_passwd}"
	printf 'Key File: %s\n' "${global_key_file}"
	printf 'Rem\t: %s\n' "${global_rem}"
}


# ssh命令帮助
_ssh_help() {
	printf '  %s\t  %s\n' 'ssh' 'Secure Shell'
	printf '  \t  %s\n' 'Usage: ssh {id}'
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
	spawn ssh ${global_user}@${global_host} -p ${global_port}
	
	# expect：等待特定的字符串或正则表达式出现，并执行相应的操作
	expect {
		# send：向进程发送字符串，并将该参数发送到进程，这个过程类似模拟人类交互
		# exp_continue：允许expect继续向下执行指令，在expect中多次匹配就需要用到
		\"*yes/no*\" { send \"yes\r\"; exp_continue }
		\"*assword:*\" { send \"${global_passwd}\r\" }
	}
	
	# interact：允许用户与进程进行交互，interact命令可以在适当的时候进行任务的干预，
	# 比如下载完ftp文件时，仍然可以停留在ftp命令行状态，以便手动的执行后续命令
	interact
	"
}


# sftp命令帮助
_sftp_help() {
	printf '  %s\t  %s\n' 'sftp' 'SSH File Transfer Protocol'
	printf '  \t  %s\n' 'Usage: sftp {id}'
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
	spawn sftp -P ${global_port} ${global_user}@${global_host}
	expect {
		\"*yes/no*\" { send \"yes\r\"; exp_continue }
		\"*assword:*\" { send \"${global_passwd}\n\" }
	}
	interact
	"
}


# scp命令帮助
_scp_help() {
	printf '  %s\t  %s\n' 'scp' 'Secure Copy Protocol'
	printf '  \t  %s\n' 'Usage: '
	printf '  \t  %s\n' 'scp {id} put {local file} {remote file}'
	printf '  \t  %s\n' 'scp {id} get {remote file} {local file}'
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
		spawn scp -v -r -p -C -P ${global_port} ${local_file} ${global_user}@${global_host}:${remote_file}
		
		expect {
			\"*yes/no*\" { send \"yes\r\"; exp_continue }
			\"*assword:*\" { send \"${global_passwd}\n\" }
		}
		interact
		"
		
	elif [[ "${type}" == 'get' ]]; then
		local remote_file="${args[2]}"
		local local_file="${args[3]}"
		expect -c "
		set timeout 60
		
		# 从远程主机复制文件到本地
		spawn scp -v -r -p -C -P ${global_port} ${global_user}@${global_host}:${remote_file} ${local_file}
		
		expect {
			\"*yes/no*\" { send \"yes\r\"; exp_continue }
			\"*assword:*\" { send \"${global_passwd}\n\" }
		}
		interact
		"
		
	else
		printf 'invalid operation\n'
	fi
}


# rsync命令帮助
_rsync_help() {
	printf '  %s\t  %s\n' 'rsync' 'Remote Sync'
	printf '  \t  %s\n' 'Usage: '
	printf '  \t  %s\n' 'rsync {id} put {local file} {remote file}'
	printf '  \t  %s\n' 'rsync {id} get {remote file} {local file}'
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
		#spawn rsync -avz --delete --progress ${local_file} ${global_user}@${global_host}:${remote_file}
		# https://www.linuxquestions.org/questions/linux-software-2/rsync-ssh-on-different-port-448112/
		spawn rsync -avz --delete --progress -e \"ssh -p ${global_port}\" ${local_file} ${global_user}@${global_host}:${remote_file}
		
		expect {
			\"*yes/no*\" { send \"yes\r\"; exp_continue }
			\"*assword:*\" { send \"${global_passwd}\n\" }
		}
		interact
		"
		
	elif [[ "${type}" == 'get' ]]; then
		local remote_file="${args[2]}"
		local local_file="${args[3]}"
		expect -c "
		set timeout 60

		# 从远程主机复制文件到本地
		spawn rsync -avz --delete --progress -e \"ssh -p ${global_port}\" ${global_user}@${global_host}:${remote_file} ${local_file} 

		expect {
			\"*yes/no*\" { send \"yes\r\"; exp_continue }
			\"*assword:*\" { send \"${global_passwd}\n\" }
		}
		interact
		"
		
	else
		printf 'invalid operation\n'
	fi
}


# 历史记录命令帮助
_history_help() {
	printf '  %s %s\n' 'history' 'History'
	printf '  \t  %s\n' 'Usage: history'
}

# 历史记录命令
_history() {
	# 参数
	local args=("$@")
	local length=${#args[@]}
	
	# 如果参数个数不等于 0 时
	if [[ length -ne 0 ]]; then
		printf 'invalid parameter\n'
		return
	fi
	
	cat -n "${global_history_file}"
}


# clear命令帮助
_clear_help() {
	printf '  %s\t  %s\n' 'clear' 'Clear'
	printf '  \t  %s\n' 'Usage: clear'
}

# clear命令
_clear() {
	# 命令参数数组
	local args=("$@")
	local length=${#args[@]}
	
	# 如果参数个数不等于 0 时
	if [[ length -ne 0 ]]; then
		printf 'invalid parameter\n'
		return
	fi
	
	# clear 命令用于清空当前终端屏幕内容
	clear
}


# quit命令帮助
_quit_help() {
	printf '  %s\t  %s\n' 'quit' 'Quit'
	printf '  \t  %s\n' 'Usage: quit'
}

# quit命令
_quit() {
	# 命令参数数组
	local args=("$@")
	local length=${#args[@]}
	
	# 如果参数个数不等于 0 时
	if [[ length -ne 0 ]]; then
		printf 'invalid parameter\n'
		return
	fi
	
	exit 0
}


# 命令帮助
_help() {
	# 参数
	local args=("$@")
	local length=${#args[@]}
	
	# 如果参数个数不等于 0 时
	if [[ length -ne 0 ]]; then
		printf 'invalid parameter\n'
		return
	fi

	_ls_help
	_get_help
	_ssh_help
	_sftp_help
	_scp_help
	_rsync_help
	_history_help
	_clear_help
	_quit_help
}


# 执行命令
_exec() {
	# 获取参数
	local input="$1"
	#echo "input=${input}"
	
	
	# 使用 eval 将输入解析成数组
	eval "array=(${input})"
	# 如果 eval 返回状态码非 0，说明执行出现错误
	if [ $? -ne 0 ]; then
		return
	fi
	
	# 命令
	# 获取数组的第一个元素
	local cmd="${array[0]}"
	#echo "cmd=${cmd}"
	
	# 命令参数数组
	# 截取数组，从索引 1 到结尾的元素
	local args=("${array[@]:1}")
	#echo "args=${args[@]}"
		
	# 命令参数数组长度
	local length=${#args[@]}
	#echo "length=${length}"
	
	
	# 执行命令历史记录指定编号的命令
	# ':0:1'：表示截取变量值从索引等于 0 开始，长度为 1
	if [[ "${cmd:0:1}" == '!' ]]; then
		# 如果参数长度不等于 0 时
		if [[ length -ne 0 ]]; then
			printf 'invalid parameter\n'
			return
		fi
		
		# ':1'：表示截取变量值从索引等于 1 开始，其后的子串
		local number="${cmd:1}"
		
		# 如果参数 number 等于空字符串
		if [[ number == '' ]]; then
			printf 'invalid parameter\n'
			return
		fi
			
		# 获取指定行号的内容
		# '-n'：参数表示静默模式
		# "${number}p"：表示打印第 number 行的内容
		input=$(sed -n "${number}p" "${global_history_file}")
			
		# 如果参数 input 等于空字符串
		if [[ "${input}" == '' ]]; then
			printf 'invalid number\n'
			return
		fi
		
		echo "${input}"
		_exec "${input}"
		
		return	
	fi
	
	
	# 记录命令到命令历史记录文件
	echo "${input}" >> "${global_history_file}"
	
	# 检查文件行数
	local count=$(wc -l < "${global_history_file}")
	
	# 记录命令到命令历史记录文件的最大行数
	local max_count=500
	
	# 如果行数超过 max_count，则使用 tail 命令截取最后 max_count 行，并重写文件
	if [[ ${count} -gt ${max_count} ]]; then
		# 截取最后 max_count 行到临时文件
		tail -n ${max_count} "${global_history_file}" > "${global_tmp_history_file}"
		# 将临时文件覆盖原文件
		mv "${global_tmp_history_file}" "${global_history_file}"
	fi
	
	
	# ls
	if [[ "${cmd}" == 'ls' ]]; then
		_ls "${args[@]}"
		return
	fi
	
	# get
	if [[ "${cmd}" == 'get' ]]; then
		_get "${args[@]}"
		return
	fi
	
	# ssh
	if [[ "${cmd}" == 'ssh' ]]; then
		_ssh "${args[@]}"
		return
	fi
	
	# sftp
	if [[ "${cmd}" == 'sftp' ]]; then
		_sftp "${args[@]}"
		return
	fi
	
	# scp
	if [[ "${cmd}" == 'scp' ]]; then
		_scp "${args[@]}"
		return
	fi
	
	# rsync
	if [[ "${cmd}" == 'rsync' ]]; then
		_rsync "${args[@]}"
	
	# history
	elif [[ "${cmd}" == 'history' ]]; then
		_history "${args[@]}"
		return
	fi
	
	# clear
	if [[ "${cmd}" == 'clear' ]]; then
		_clear "${args[@]}"
		return
	fi
	
	# quit
	if [[ "${cmd}" == 'quit' ]]; then	
		_quit "${args[@]}"
		return
	fi
	
	# help
	if [[ "${cmd}" == 'help' ]]; then
		_help "${args[@]}"
		return
	fi
	
	# command not found
	printf "%s: command not found\n" "${cmd}"
	return
}

main() {
	# 读取服务器配置文件
	read_server_file

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
	
		# 如果输入为空字符时
		if [[ "${input}" == '' ]]; then
			continue
		fi
		
		# 执行
		_exec "${input}"
	done
}

main