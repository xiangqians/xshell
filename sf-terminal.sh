#!/bin/bash

##########
# auth: xiangqian
# date: 18:39 ‎2023‎/0‎1‎/‎17‎
##########


# server配置
svrconf="./test.txt"

# 当前时间
function now(){
	echo `date "+%Y-%m-%d %H:%M:%S.%N"`
}

# 字符串转为数组
function convStrToArr(){
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
	# convStrToArr 'test'
	# echo $?
	#return 0	

	# 获取返回值方式二：echo
	# 获取返回值：
	# r=($(convStrToArr 'test'))
	# echo ${#r[*]} ${r[*]}
	echo ${arr[*]}
}

# 服务器列表
function list(){
	# 双引号会先解析变量的内容
	# 单引号包裹的内容表示原样输出
	
	# format
	format='%-2s %-20s %-6s %-20s %-30s %s\n'
	printf "${format}" 'ID' 'HOST' 'PORT' 'USER' 'PASSWD' 'REM'

	# server id
	id=1
	#while read line; do
	while read line || [ -n "$line" ]; do
		#echo $id $line
		arr=($(convStrToArr "$line"))
		#echo ${#arr[*]} ${arr[*]}
		# 数组长度为 5 时才显示
		if [ ${#arr[@]} -ne 5 ]; then
			printf "unable to parse\n"
			exit
		fi
		
		printf "${format}" "$id" "${arr[0]}" "${arr[1]}" "${arr[2]}" "${arr[3]}" "${arr[4]}"
		# id++
		let id++
		
: << !
		for e in ${arr[@]}
		do
			echo $e
		done
!

	done < $svrconf
}

list

while true; do
	printf '\n'
	read -p '$ ' p
	#echo $p	
	if [[ $p == '' ]]; then
		continue
	
	# 帮助命令
	elif [[ $p == 'h' ]]; then
		# ls
		printf '%s\t%s\n' 'ls' 'server list'
		printf '\t%s\n' 'eg: ls'
		# add
		printf '%s\t%s\n' 'add' 'add server'
		printf '\t%s\n' 'eg: add {host} {port} {user} {passwd} {rem}'
		# del
		printf '%s\t%s\n' 'del' 'delete server'
		printf '\t%s\n' 'eg: del {id}'
		# q
		printf '%s\t%s\n' 'q' 'quit'
		continue
	
	# server列表
	elif [[ $p == 'ls' ]]; then
		list
		continue
	
	# 新增server
	elif [[ $p == 'add '* ]]; then
		p=${p: 4}
		if [[ $p == "" ]]; then
			printf 'invalid server\n'
			continue
		fi
		
		arr=($(convStrToArr "$p"))
		if [ ${#arr[*]} -ne 5 ]; then 
			printf 'invalid server\n'
			continue
		fi
		
		sed -i '$a \'"$p" $svrconf
		continue
	
	# 删除server
	elif [[ $p == 'del '* ]]; then
		p=${p: 4}
		id=$((p+0))
		sed -i "${id}d" $svrconf
		printf '\n'
		list
		continue
	
	# 更新server
	elif [[ $p == 'upd' ]]; then
		
		continue
	
	# 进入server
	elif [[ $p == 'cd' ]]; then
		
		continue
	
	elif [[ $p == 'q' ]]; then
		break
		
	else
		printf "${p}: command not found\n"
		continue
	fi;
done

#ln=`expr $id - 1`
#sed -i "${ln}i\\$p" $svrconf
# sed -i '2d' test.txt
# sed -i '2i\ test123' test.txt
# sed -n '2p' test.txt



