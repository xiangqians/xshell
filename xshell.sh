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

# 判断服务器配置文件是否存在
if [ ! -f ${SERVER_CONF_FILE} ]; then
	# 服务器配置文件不存在则创建
	touch ${SERVER_CONF_FILE}
	# $? 获取上一个命令执行结果，如果非0（异常）则退出程序
	if [ $? -ne 0 ]; then
		exit 1
	fi
fi

# 读取服务配置文件
function read_server_conf_func(){
	# 回调函数
	local callback_func=$1
	
	# 行号
	local nu=1
	
	# 服务器id
	local id=1
	
	# id行号
	local id_nu=1
	
	# 定义一个空map
	declare -A map=()
	
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
			local host=${map['host']}
			if [[ "$host" != '' ]]; then
				map['id']=$id
				map['id_nu']=$id_nu
				
				$callback_func map $2 $3
				local r=$?
				
				# 清空map
				for key in ${!map[@]}; do
					unset map[$key]
				done
				
				if [[ "$r" != '0' ]]; then
					return $r
				fi
				
				let id++
			fi
			id_nu=$nu
		
		# host
		elif [[ $line =~ ^host: ]]; then
			local host=${line:5}
			host="${host#"${host%%[![:space:]]*}"}"
			host="${host%"${host##*[![:space:]]}"}"
			map['host']=$host
			map['host_nu']=$nu
		
		# port
		elif [[ $line =~ ^port: ]]; then
			local port=${line:5}
			port="${port#"${port%%[![:space:]]*}"}"
			port="${port%"${port##*[![:space:]]}"}"
			map['port']=$port
			map['port_nu']=$nu
		
		# user
		elif [[ $line =~ ^user: ]]; then
			local user=${line:5}
			user="${user#"${user%%[![:space:]]*}"}"
			user="${user%"${user##*[![:space:]]}"}"
			map['user']=$user
			map['user_nu']=$nu
		
		# passwd
		elif [[ $line =~ ^passwd: ]]; then
			local passwd=${line:7}
			passwd="${passwd#"${passwd%%[![:space:]]*}"}"
			passwd="${passwd%"${passwd##*[![:space:]]}"}"
			map['passwd']=$passwd
			map['passwd_nu']=$nu
		
		# key-file
		elif [[ $line =~ ^key-file: ]]; then
			local key_file=${line:9}
			key_file="${key_file#"${key_file%%[![:space:]]*}"}"
			key_file="${key_file%"${key_file##*[![:space:]]}"}"
			map['key_file']=$key_file
			map['key_file_nu']=$nu
		
		# rem
		elif [[ $line =~ ^rem: ]]; then
			local rem=${line:4}
			rem="${rem#"${rem%%[![:space:]]*}"}"
			rem="${rem%"${rem##*[![:space:]]}"}"
			map['rem']=$rem
			map['rem_nu']=$nu
		fi
		
		let nu++
	done < ${SERVER_CONF_FILE}
	
	local host=${map['host']}
	if [[ "$host" != '' ]]; then
		map['id']=$id
		map['id_nu']=$id_nu
		
		$callback_func map $2 $3
		local r=$?
		
		# 清空map
		for key in ${!map[@]}; do
			unset map[$key]
		done
		
		return $r
	fi
	
	return 0
}

# 定义错误码Map
declare -A ERR_CODE_MAP=()
ERR_CODE_MAP['invalid_option']='invalid option: %s\n'
ERR_CODE_MAP['option_requires_a_parameter_value']='option -%s requires a parameter value\n'
ERR_CODE_MAP['invalid_host']='invalid host: %s\n'
ERR_CODE_MAP['invalid_port']='invalid port: %s\n'
ERR_CODE_MAP['invalid_user']='invalid user: %s\n'
ERR_CODE_MAP['invalid_passwd']='invalid passwd: %s\n'
ERR_CODE_MAP['invalid_key_file']='invalid key file: %s\n'
ERR_CODE_MAP['invalid_rem']='invalid rem: %s\n'
ERR_CODE_MAP['invalid_parameter']='invalid parameter: %s\n'
ERR_CODE_MAP['id_not_exist']='id does not exist: %s\n'

# 打印错误码消息
function print_err_code_msg_func(){
	printf "${ERR_CODE_MAP[$1]}" "$2"
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
	map=$1
	
	#echo map ${map[@]}
	
	local id=${map['id']}
	local id_nu=${map['id_nu']}
	local host=${map['host']}
	local host_nu=${map['host_nu']}
	local port=${map['port']}
	local port_nu=${map['port_nu']}
	local user=${map['user']}
	local user_nu=${map['user_nu']}
	local passwd=${map['passwd']}
	local passwd_nu=${map['passwd_nu']}
	local key_file=${map['key_file']}
	local key_file_nu=${map['key_file_nu']}
	local rem=${map['rem']}
	local rem_nu=${map['rem_nu']}
	
	printf "${FORMAT}" "${id}" "${host}" "${port}" "${user}" "******" "${rem}"
	#printf "${FORMAT}" "${id}(${id_nu})" "${host}(${host_nu})" "${port}(${port_nu})" "${user}(${user_nu})" "******(${passwd_nu}/${key_file_nu})" "${rem}(${rem_nu})"
	
	return 0
}

# 服务器列表
function ls_func(){
	printf "${FORMAT}" 'ID' 'HOST' 'PORT' 'USER' 'PASSWD/KEY-FILE' 'REM'
	read_server_conf_func ls_callback_func
}

# add命令帮助
function add_help_func(){
	printf '  %s\t%s\n' 'add' 'add server'
	printf '  \t%s\t%s\n' 'Usage: add -h {host} -P {port} -u {user} [-p {passwd}] [-k {key file}] -r {rem}'
}

# 新增服务器
function add_func(){
	#echo $# $@
	
	if [[ $# -eq 0 ]]; then
		add_help_func
		return
	fi
	
	local host=
	local port=
	local user=
	local passwd=
	local key_file=
	local rem=
	
	# 设置getopts命令区分选项的大小写（默认是不区分大小写的）
	export POSIXLY_CORRECT=1
	
	# 第一次使用 getopts 运行脚本有效，但第二次运行它时不起作用问题：
	# source 在当前 shell 的执行上下文中运行指定文件中的 bash 命令。
	# 该执行上下文包括变量 OPTIND，getopts 使用它来记住“当前”参数索引。
	# 因此，当您重复 source 脚本时，getopts 的每次调用都从上一次调用处理的最后一个参数之后的参数索引开始。
	# 在脚本开头将 OPTIND 重置为 1，或者使用 bash getopt.sh 调用脚本。(通常 getopts 作为通过 she-bang 执行的脚本的一部分被调用，因此它有自己的执行上下文，您不必担心它的变量。)
	OPTIND=1
	
	# 在Shell脚本中，getopts是一个内置的命令，用于解析命令行参数
	while getopts ":h:P:u:p:k:r:" opt; do
		case $opt in
			# 选项 -h
			h)
				#echo "选项 -h，参数为 $OPTARG"
				host=$OPTARG
				;;
			
			# 选项 -P
			P)
				#echo "选项 -P，参数为 $OPTARG"
				port=$OPTARG
				;;
			
			# 选项 -u
			u)
				#echo "选项 -u，参数为 $OPTARG"
				user=$OPTARG
				;;
			
			# 选项 -p
			p)
				#echo "选项 -p，参数为 $OPTARG"
				passwd=$OPTARG
				;;
			
			# 选项 -k
			k)
				#echo "选项 -k，参数为 $OPTARG"
				key_file=$OPTARG
				;;
			
			# 选项 -r
			r)
				#echo "选项 -r，参数为 $OPTARG"
				rem=$OPTARG
				;;
			
			# 选项 -$OPTARG 需要一个参数值
			:)				
				print_err_code_msg_func option_requires_a_parameter_value "$OPTARG"
				return
				;;
				
			# ?
			\?)
				#echo "无效选项: -$OPTARG"
				print_err_code_msg_func invalid_option "-$OPTARG"
				return
				;;
		esac
	done
	
	if [[ $host == '' ]]; then
		print_err_code_msg_func invalid_host "$host"
		return
	fi
	
	if [[ $port == '' ]]; then
		print_err_code_msg_func invalid_port "$port"
		return
	fi
	
	if [[ $user == '' ]]; then
		print_err_code_msg_func invalid_user "$user"
		return
	fi
	
	if [[ $passwd == '' ]]; then
		if [[ $key_file == '' ]]; then
			print_err_code_msg_func invalid_passwd "$passwd"
			return
		fi
	fi
	
	
	if [[ $rem == '' ]]; then
		print_err_code_msg_func invalid_rem "$rem"
		return
	fi
	
	# 在文件的结尾追加一行
	# -i：在原始文件上进行直接修改
	# $ ：匹配文件的最后一行位置，表示文件末尾
	# a\：append，表示追加
	#
	# sed -i 空文件无法追加
	# 为什么呢？
	# 因为sed是基于行来处理的文件流编辑器，如果文件为空的话，它是处理不了的！
	# Sed is a stream editor.A stream editor is used to perform basic text transformations on an input stream (a file or input from a pipeline).
	# While in some ways similar to an editor which permits scripted edits (such as ed), 
	# sed works by making only one pass  over the  input(s), and  is  consequently more efficient.
	# But it is sed’s ability to filter text in a pipeline which particularly distin-guishes it from other types of editors.
	# Sed是一个流编辑器。流编辑器用于对输入流（文件或来自管道的输入）执行基本的文本转换。尽管在某种程度上类似于允许脚本编辑（例如ed）的编辑器，但sed通过仅对输入进行一次传递来进行工作，因此效率更高。
	# 但这是sed过滤管道中文本的能力，尤其可以区别于其他类型的编辑器。
	# 那么这种情形要如何处理呢？
	# 可以加个判断，如果文件存在但为空的话，使用echo命令来添加，如果非空的话，则使用sed命令。
	if test -s ${SERVER_CONF_FILE}; then
		sed -i '$a\''-' ${SERVER_CONF_FILE}
	else
		echo -e '-' >> ${SERVER_CONF_FILE}
	fi
	sed -i '$a\''\t''host: '"$host" ${SERVER_CONF_FILE}
	sed -i '$a\''\t''port: '"$port" ${SERVER_CONF_FILE}
	sed -i '$a\''\t''user: '"$user" ${SERVER_CONF_FILE}
	sed -i '$a\''\t''passwd: '"$passwd" ${SERVER_CONF_FILE}
	sed -i '$a\''\t''key-file: '"$key_file" ${SERVER_CONF_FILE}
	sed -i '$a\''\t''rem: '"$rem" ${SERVER_CONF_FILE}
	return
}

# 删除服务器信息命令帮助
function del_help_func(){
	printf '  %s\t%s\n' 'del' 'delete server'
	printf '  \t%s\n' 'Usage: del {id}'
}

# 删除服务器信息回调
function del_callback_func(){
	map=$1
	local id=$2
	if [[ "$id" == "${map['id']}" ]]; then
		local rem_nu=${map['rem_nu']}
		if [[ "${rem_nu}" != '' ]]; then
			sed -i "${rem_nu}d" ${SERVER_CONF_FILE}
		fi
		
		local key_file_nu=${map['key_file_nu']}
		if [[ "${key_file_nu}" != '' ]]; then
			sed -i "${key_file_nu}d" ${SERVER_CONF_FILE}
		fi
		
		local passwd_nu=${map['passwd_nu']}
		if [[ "${passwd_nu}" != '' ]]; then
			sed -i "${passwd_nu}d" ${SERVER_CONF_FILE}
		fi
		
		local user_nu=${map['user_nu']}
		if [[ "${user_nu}" != '' ]]; then
			sed -i "${user_nu}d" ${SERVER_CONF_FILE}
		fi
		
		local port_nu=${map['port_nu']}
		if [[ "${port_nu}" != '' ]]; then
			sed -i "${port_nu}d" ${SERVER_CONF_FILE}
		fi
		
		local host_nu=${map['host_nu']}
		if [[ "${host_nu}" != '' ]]; then
			sed -i "${host_nu}d" ${SERVER_CONF_FILE}
		fi
		
		local id_nu=${map['id_nu']}
		if [[ "${id_nu}" != '' ]]; then
			sed -i "${id_nu}d" ${SERVER_CONF_FILE}
		fi

		return 1
	fi
	return 0
}

# 删除服务器信息
function del_func(){
	if [[ $# -eq 0 ]]; then
		del_help_func
		return
	fi
	
	if [[ $# -ne 1 ]]; then
		local str="$@"
		print_err_code_msg_func invalid_parameter "$str"
		return
	fi
	
	local id=$1
	read_server_conf_func del_callback_func "$id"
	local r=$?
	if [[ $r -eq 0 ]]; then
		print_err_code_msg_func id_not_exist "$id"
	fi
}

# 更新服务器信息命令帮助
function upd_help_func(){
	printf '  %s\t%s\n' 'upd' 'update server'
	printf '  \t%s\t%s\n' 'Usage: upd {id} [-h {host}] [-P {port}] [-u {user}] [-p {passwd}] [-k {key file}] [-r {rem}]'
}

# 更新服务器信息回调
function upd_callback_func(){
	map=$1
	local id=$2
	if [[ "$id" == "${map['id']}" ]]; then
		upd_map=$3
		echo upd_map ${upd_map[@]}
		
		local rem=${upd_map['rem']}
		local rem_nu=${map['rem_nu']}
		if [[ "${rem}" != '' && "${rem_nu}" != '' ]]; then
			# ${rem_nu}a\ 表示在第 ${rem_nu} 行后添加文本
			sed -i ${rem_nu}'a\''\t''rem: '"$rem" ${SERVER_CONF_FILE}
			# 删除第 ${rem_nu} 行
			sed -i ${rem_nu}'d' ${SERVER_CONF_FILE}
		fi
		
		
		local key_file=${upd_map['key_file']}
		local key_file_nu=${map['key_file_nu']}
		if [[ "${key_file}" != '' && "${key_file_nu}" != '' ]]; then
			sed -i ${key_file_nu}'a\''\t''key-file: '"$key_file" ${SERVER_CONF_FILE}
			sed -i ${key_file_nu}'d' ${SERVER_CONF_FILE}
		fi
		
		local passwd=${upd_map['passwd']}
		local passwd_nu=${map['passwd_nu']}
		if [[ "${passwd}" != '' && "${passwd_nu}" != '' ]]; then
			sed -i ${passwd_nu}'a\''\t''passwd: '"$passwd" ${SERVER_CONF_FILE}
			sed -i ${passwd_nu}'d' ${SERVER_CONF_FILE}
		fi
		
		local user=${upd_map['user']}
		local user_nu=${map['user_nu']}
		if [[ "${user}" != '' && "${user_nu}" != '' ]]; then
			sed -i ${user_nu}'a\''\t''user: '"$user" ${SERVER_CONF_FILE}
			sed -i ${user_nu}'d' ${SERVER_CONF_FILE}
		fi
		
		local port=${upd_map['port']}
		local port_nu=${map['port_nu']}
		if [[ "${port}" != '' && "${port_nu}" != '' ]]; then
			sed -i ${port_nu}'a\''\t''user: '"$port" ${SERVER_CONF_FILE}
			sed -i ${port_nu}'d' ${SERVER_CONF_FILE}
		fi
		
		local host=${upd_map['host']}
		local host_nu=${map['host_nu']}
		if [[ "${host}" != '' && "${host_nu}" != '' ]]; then
			sed -i ${host_nu}'a\''\t''host: '"$host" ${SERVER_CONF_FILE}
			sed -i ${host_nu}'d' ${SERVER_CONF_FILE}
		fi
		
		local id=${upd_map['id']}
		local id_nu=${map['id_nu']}
		if [[ "${id}" != '' && "${id_nu}" != '' ]]; then
			sed -i ${id_nu}'a\''\t''id: '"$id" ${SERVER_CONF_FILE}
			sed -i ${id_nu}'d' ${SERVER_CONF_FILE}
		fi

		return 1
	fi
	return 0
}

# 更新服务器信息
function upd_func(){
	if [[ $# -eq 0 || $# -eq 1 ]]; then
		upd_help_func
		return
	fi
	
	declare -A upd_map=()
	
	export POSIXLY_CORRECT=1
	# 从第二个参数开始解析（第一个参数是server id）
	OPTIND=2
	while getopts ":h:P:u:p:k:r:" opt; do
		case $opt in
			# 选项 -h
			h)
				upd_map['host']=$OPTARG
				;;
			
			# 选项 -P
			P)
				upd_map['port']=$OPTARG
				;;
			
			# 选项 -u
			u)
				upd_map['user']=$OPTARG
				;;
			
			# 选项 -p
			p)
				upd_map['passwd']=$OPTARG
				;;
			
			# 选项 -k
			k)
				upd_map['key_file']=$OPTARG
				;;
			
			# 选项 -r
			r)
				upd_map['rem']=$OPTARG
				;;
			
			# 选项 -$OPTARG 需要一个参数值
			:)				
				print_err_code_msg_func option_requires_a_parameter_value "$OPTARG"
				return
				;;
			
			# ?
			\?)
				print_err_code_msg_func invalid_option "-$OPTARG"
				return
				;;
		esac
	done
	
	local id=$1
	upd_map['id']=$id
	read_server_conf_func upd_callback_func "$id" upd_map
	local r=$?
	
	for key in ${!upd_map[@]}; do
		# 删除关联map中的key
		unset upd_map[$key]
	done
	
	if [[ $r -eq 0 ]]; then
		print_err_code_msg_func id_not_exist "$id"
	fi
	return 
}

# 获取服务器信息命令帮助
function get_help_func(){
	printf '  %s\t%s\n' 'get' 'get server'
	printf '  \t%s\n' 'Usage: get {id}'
}

# 获取服务器信息回调
function get_callback_func(){
	map=$1
	local target_id=$2
	local id=${map['id']}
	if [[ "$id" == "$target_id" ]]; then
		local host=${map['host']}
		local port=${map['port']}
		local user=${map['user']}
		local passwd=${map['passwd']}
		local key_file=${map['key_file']}
		local rem=${map['rem']}
		
		printf 'host\t: %s\n' "${host}"
		printf 'port\t: %s\n' "${port}"
		printf 'user\t: %s\n' "${user}"
		printf 'passwd\t: %s\n' "${passwd}"
		printf 'key file: %s\n' "${key_file}"
		printf 'rem\t: %s\n' "${rem}"
		
		return 1
	fi
	
	return 0
}

# 获取服务器信息
function get_func(){
	if [[ $# -eq 0 ]]; then
		get_help_func
		return
	fi
	
	if [[ $# -ne 1 ]]; then
		local str="$@"
		print_err_code_msg_func invalid_parameter "$str"
		return
	fi
	
	local id=$1
	read_server_conf_func get_callback_func "$id"
	local r=$?
	if [[ $r -eq 0 ]]; then
		print_err_code_msg_func id_not_exist "$id"
	fi
}

# ssh命令帮助
function ssh_help_func(){
	printf '  %s\t%s\n' 'ssh' ''
	printf '  \t%s\t%s\n' 'Usage: ssh {id}'
}

# ssh命令回调
function ssh_callback_func(){
	map=$1
	local id=$2
	if [[ "$id" == "${map['id']}" ]]; then
		local host=${map['host']}
		local port=${map['port']}
		local user=${map['user']}
		local passwd=${map['passwd']}
		local key_file=${map['key_file']}
		local rem=${map['rem']}
		
		# 使用expect自动登录远程服务器
		expect -c "
		set timeout 60
		spawn ssh ${user}@${host} -p ${port}
		expect {
			\"*yes/no*\" { send \"yes\r\"; exp_continue }
			\"*assword:*\" { send \"${passwd}\r\" }
		}
		interact
		"
		return 1
	fi
	return 0
}

# ssh命令
function ssh_func(){
	if [[ $# -eq 0 ]]; then
		ssh_help_func
		return
	fi
	
	if [[ $# -ne 1 ]]; then
		local str="$@"
		print_err_code_msg_func invalid_parameter "$str"
		return
	fi
	
	local id=$1
	read_server_conf_func ssh_callback_func "$id"
	local r=$?
	if [[ $r -eq 0 ]]; then
		print_err_code_msg_func id_not_exist "$id"
	fi
}

# sftp命令帮助
function sftp_help_func(){
	printf '  %s\t%s\n' 'sftp' ''
	printf '  \t%s\t%s\n' 'Usage: sftp {id}'
}

# sftp命令回调
function sftp_callback_func(){
	map=$1
	local id=$2
	if [[ "$id" == "${map['id']}" ]]; then
		local host=${map['host']}
		local port=${map['port']}
		local user=${map['user']}
		local passwd=${map['passwd']}
		local key_file=${map['key_file']}
		expect -c "
		set timeout 60
		puts \"  put\"
		puts \"  \tUsage: put \[-r\] {local file name} {remote file name}\"
		puts \"  get\"
		puts \"  \tUsage: get \[-r\] {remote file name} {local file name}\"
		puts \"\"
		spawn sftp -P $port $user@$host
		expect {
			\"*yes/no*\" { send \"yes\r\"; exp_continue }
			\"*assword:*\" { send \"${passwd}\r\" }
		}
		interact
		"
		return 1
	fi
	return 0
}

# sftp命令
function sftp_func(){
	if [[ $# -eq 0 ]]; then
		sftp_help_func
		return
	fi
	
	if [[ $# -ne 1 ]]; then
		local str="$@"
		print_err_code_msg_func invalid_parameter "$str"
		return
	fi
	
	local id=$1
	read_server_conf_func sftp_callback_func "$id"
	local r=$?
	if [[ $r -eq 0 ]]; then
		print_err_code_msg_func id_not_exist "$id"
	fi
}

# scp命令帮助
function scp_help_func(){
	printf '  %s\t%s\n' 'scp' ''
	printf '  \t%s\t%s\n' 'Usage: '
	printf '  \t\t%s\t%s\n' 'scp {id} put {local file name} {remote file name}'
	printf '  \t\t%s\t%s\n' 'scp {id} get {remote file name} {local file name}'
}

# scp命令回调
function scp_callback_func(){
	return 1
}

# scp命令
function scp_func(){
	if [[ $# -eq 0 ]]; then
		scp_help_func
		return
	fi
	
	if [[ $# -ne 1 ]]; then
		local str="$@"
		print_err_code_msg_func invalid_parameter "$str"
		return
	fi
	
	local id=$1
	read_server_conf_func sftp_callback_func "$id"
	local r=$?
	if [[ $r -eq 0 ]]; then
		print_err_code_msg_func id_not_exist "$id"
	fi
}

# rsync命令帮助
function rsync_help_func(){
	printf '  %s\t%s\n' 'rsync' ''
	printf '  \t%s\t%s\n' 'Usage: '
	printf '  \t\t%s\t%s\n' 'rsync {id} put {local file name} {remote file name}'
	printf '  \t\t%s\t%s\n' 'rsync {id} get {remote file name} {local file name}'
}

# quit命令帮助
function quit_help_func(){
	printf '  %s\t%s\n' 'quit' 'quit'
	printf '  \t%s\n' 'Usage: quit'
}

# 命令帮助
function help_func(){
	ls_help_func
	add_help_func
	del_help_func
	upd_help_func
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
	# -p prompt 提示字符串
	read -p 'xshell$ ' cmd str
	if [[ "$cmd" == '' ]]; then
		continue
	fi
	
	#echo cmd $cmd
	#echo str $str

	arr=()
	index=0
	
	while true; do
		# 去除字符串前后空格
		str="${str#"${str%%[![:space:]]*}"}"
		str="${str%"${str##*[![:space:]]}"}"
		
		# ${str%%pattern*}: 删除从 str 开头开始匹配的最长的 pattern*
		# [[:space:]]: 匹配任何一个空白字符
		# 例如，如果str的值为"This is a sample string"，那么${str%%[[:space:]]*}将返回"This"，即删除了第一个空格及其后的所有字符
		
		substr=
		
		# 判断字符串是否以 双引号 开头
		if [[ "$str" == '"'* ]]; then
			str=${str:1}
			substr=${str%%\"[[:space:]]*}
			if [[ "$str" == "$substr" ]]; then
				substr=${str%%\"*}
				str=
			else
				len=${#substr}
				let len=len+2
				str=${str:${len}}
			fi
		
		# 空格分隔
		else
			substr=${str%%[[:space:]]*}
			len=${#substr}
			let len=len+1
			str=${str:${len}}
		fi
		if [[ $substr == '' ]]; then
			break
		fi
		
		#echo $index $substr '('$str')'
		arr[$index]=$substr
		let index++
	done
	
	#echo arr ${#arr[@]} ${arr[@]}
	
	# help
	if [[ "$cmd" == 'help' ]]; then
		help_func
	
	# ls
	elif [[ "$cmd" == 'ls' ]]; then
		ls_func
	
	# add
	elif [[ "$cmd" == 'add' ]]; then
		add_func "${arr[@]}"
	
	# del
	elif [[ "$cmd" == 'del' ]]; then
		del_func "${arr[@]}"
	
	# upd
	elif [[ "$cmd" == 'upd' ]]; then
		upd_func "${arr[@]}"
	
	# get
	elif [[ "$cmd" == 'get' ]]; then
		get_func "${arr[@]}"
	
	# info
	elif [[ "$cmd" == 'info' ]]; then
		info_func "${arr[@]}"
	
	# ssh
	elif [[ "$cmd" == 'ssh' ]]; then
		ssh_func "${arr[@]}"
	
	# sftp
	elif [[ "$cmd" == 'sftp' ]]; then
		sftp_func "${arr[@]}"
	
	# scp
	elif [[ "$cmd" == 'scp' ]]; then
		scp_func "${arr[@]}"
	
	# rsync
	elif [[ "$cmd" == 'rsync' ]]; then
		rsync_func "${arr[@]}"
	
	# quit
	elif [[ "$cmd" == 'quit' ]]; then
		break
	
	# command not found
	else
		printf "%s: command not found\n" "${cmd}"
	fi
done

exit 0