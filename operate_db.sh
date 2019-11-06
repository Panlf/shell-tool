#! /bin/bash
database_names=`mysql -uroot -proot -h 127.0.0.1 -P3360 -e "show databases like '%_test';" | awk 'NR>1{print $1}'`
for name in $database_names;
do
    #echo $name
    table_names=`mysql -uroot -proot -h 127.0.0.1 -P3360 -e "select table_name from information_schema.tables where table_schema='$name' | awk 'NR>1{print $1}'`
    for table_name in $table_names;
		do
		#echo $table_name
		table_count=`mysql -uroot -proot -h 127.0.0.1 -P3360 -e "select max(id) as count from $name.$table_name;" | tail -1`
		echo "$name.$table_name=$table_count" >> /tmp/count.log
    done
done








