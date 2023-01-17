#!/bin/bash

# sed -i '2d' test.txt
# sed -i '2i\ test123' test.txt
# sed -n '2p' test.txt

# add
# del
# upd
# qry

function list(){
	format="%-2s %-20s %-6s %-20s %-30s %s\n"
	printf "${format}" "ID" "HOST" "PORT" "USER" "PASSWD" "REM"

	# server id
	id=1
	#while read line; do
	while read line || [ -n "$line" ]; do
		#echo $id $line
		
		# 以 , 号分隔字符串，通过 IFS 变量设置分隔符
		# 保存当前shell默认的分割符
		OLD_IFS="$IFS"
		# 将shell的分割符号改为 ,
		IFS=","
		arr=(${line})
		# 恢复shell默认分割符配置
		IFS="$OLD_IFS"
		# 数组内容
		#echo ${arr[@]}
		# 数组长度为 5 时才显示
		if [ ${#arr[@]} -eq 5 ]; then
			printf "${format}" "$id" "${arr[0]}" "${arr[1]}" "${arr[2]}" "${arr[3]}" "${arr[4]}"
			# id++
			let id++
		fi

		#for e in ${arr[@]}
		#do
		#	echo "'"$e"'"
		#done

	done < ./test.txt
}

list



