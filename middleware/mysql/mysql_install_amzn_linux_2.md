# MySQL Replication & Dump

# Provisioning
```
テスト
AWS EC2*2
MySQL5.7
user: root
pass: root

基本インストール方法
https://qiita.com/2no553/items/952dbb8df9a228195189

パスワード変更
https://qiita.com/RyochanUedasan/items/9a49309019475536d22a
```



# Replication
https://dev.mysql.com/doc/refman/5.6/ja/replication.html

チェックリスト
```
step1
  master
    binary log on!              [my.cnf/ log-bin]  => [master status/ File: ip-10-0-21-20-bin.000001]
    set id                      [my.cnf/ server-id=1]
  slave
    set id                      [my.cnf/ server-id=2]

step2
  master
    create user for slave       [mysql> grant replication slave on *.* to 'repl'@'10...]
    check binary log position   [master status/ Position: 446]

```

- master
```
$ sudo vi etc/my.cnf
  [mysqld]
  log-bin
  server-id=1
  # log-bin=mysql-bin   prefixをつけられる

$ systemctl restart mysqld
```

- slave
```
$ sudo vi etc/my.cnf
  [mysqld]
  server-id=2

$ systemctl restart mysqld
```

- master
```
> grant replication slave on *.* to 'repl'@'10.0.11.20' identified by 'repl';

> select Host, User from mysql.user; ★
+------------+---------------+
| Host       | User          |
+------------+---------------+
| %          | zabbix        |
| 10.0.11.20 | repl          |
| localhost  | mysql.session |
| localhost  | mysql.sys     |
| localhost  | root          |
+------------+---------------+

> show master status\G
*************************** 1. row ***************************
             File: ip-10-0-21-20-bin.000001
         Position: 446
     Binlog_Do_DB:
 Binlog_Ignore_DB:
Executed_Gtid_Set:
1 row in set (0.00 sec)
```


- slave
```
> change master to master_host = '10.0.21.20',master_user = 'repl',master_password = 'repl',master_log_file = 'ip-10-0-21-20-bin.000001',master_log_pos = 446;

> start slave;

> show slave status\G
*************************** 1. row ***************************
               Slave_IO_State: Connecting to master
                  Master_Host: 10.0.21.20
                  Master_User: repl
                  Master_Port: 3306
                Connect_Retry: 60
              Master_Log_File: ip-10-0-21-20-bin.000001
          Read_Master_Log_Pos: 446
               Relay_Log_File: ip-10-0-11-20-relay-bin.000001
                Relay_Log_Pos: 4
        Relay_Master_Log_File: ip-10-0-21-20-bin.000001
             Slave_IO_Running: Connecting
            Slave_SQL_Running: Yes
              Replicate_Do_DB:
          Replicate_Ignore_DB:
           Replicate_Do_Table:
       Replicate_Ignore_Table:
      Replicate_Wild_Do_Table:
  Replicate_Wild_Ignore_Table:
                   Last_Errno: 0
                   Last_Error:
                 Skip_Counter: 0
          Exec_Master_Log_Pos: 446
              Relay_Log_Space: 154
              Until_Condition: None
               Until_Log_File:
                Until_Log_Pos: 0
           Master_SSL_Allowed: No
           Master_SSL_CA_File:
           Master_SSL_CA_Path:
              Master_SSL_Cert:
            Master_SSL_Cipher:
               Master_SSL_Key:
        Seconds_Behind_Master: NULL
Master_SSL_Verify_Server_Cert: No
                Last_IO_Errno: 0
                Last_IO_Error:
               Last_SQL_Errno: 0
               Last_SQL_Error:
  Replicate_Ignore_Server_Ids:
             Master_Server_Id: 0
                  Master_UUID:
             Master_Info_File: /var/lib/mysql/master.info
                    SQL_Delay: 0
          SQL_Remaining_Delay: NULL
      Slave_SQL_Running_State: Slave has read all relay log; waiting for more updates
           Master_Retry_Count: 86400
                  Master_Bind:
      Last_IO_Error_Timestamp:
     Last_SQL_Error_Timestamp:
               Master_SSL_Crl:
           Master_SSL_Crlpath:
           Retrieved_Gtid_Set:
            Executed_Gtid_Set:
                Auto_Position: 0
         Replicate_Rewrite_DB:
                 Channel_Name:
           Master_TLS_Version:
1 row in set (0.00 sec)
```

Slave_IO_Running: Yes、Slave_SQL_Running: Yesだったら設定OK!つまり上記NG。

疎通確認
```
$ curl -vv telnet://<master_ip>:3306 --output /dev/null
```
ネットワーク関係ならAWS側の設定を確認。今回はセキュリティでのインバウンド設定に不備。
もう一度疎通確認してOKなら、statusコマンド再度実行。

もう一度
```
mysql> show slave status\G
*************************** 1. row ***************************
               Slave_IO_State: Waiting for master to send event
                  Master_Host: 10.0.21.20
                  Master_User: repl
                  Master_Port: 3306
                Connect_Retry: 60
              Master_Log_File: ip-10-0-21-20-bin.000001
          Read_Master_Log_Pos: 446
               Relay_Log_File: ip-10-0-11-20-relay-bin.000002
                Relay_Log_Pos: 328
        Relay_Master_Log_File: ip-10-0-21-20-bin.000001
             Slave_IO_Running: Yes
            Slave_SQL_Running: Yes
              Replicate_Do_DB:
          Replicate_Ignore_DB:
           Replicate_Do_Table:
       Replicate_Ignore_Table:
      Replicate_Wild_Do_Table:
  Replicate_Wild_Ignore_Table:
                   Last_Errno: 0
                   Last_Error:
                 Skip_Counter: 0
          Exec_Master_Log_Pos: 446
              Relay_Log_Space: 543
              Until_Condition: None
               Until_Log_File:
                Until_Log_Pos: 0
           Master_SSL_Allowed: No
           Master_SSL_CA_File:
           Master_SSL_CA_Path:
              Master_SSL_Cert:
            Master_SSL_Cipher:
               Master_SSL_Key:
        Seconds_Behind_Master: 0
Master_SSL_Verify_Server_Cert: No
                Last_IO_Errno: 0
                Last_IO_Error:
               Last_SQL_Errno: 0
               Last_SQL_Error:
  Replicate_Ignore_Server_Ids:
             Master_Server_Id: 1
                  Master_UUID: 270ec95b-d7a2-11ea-b55a-0a9dc8630d08
             Master_Info_File: /var/lib/mysql/master.info
                    SQL_Delay: 0
          SQL_Remaining_Delay: NULL
      Slave_SQL_Running_State: Slave has read all relay log; waiting for more updates
           Master_Retry_Count: 86400
                  Master_Bind:
      Last_IO_Error_Timestamp:
     Last_SQL_Error_Timestamp:
               Master_SSL_Crl:
           Master_SSL_Crlpath:
           Retrieved_Gtid_Set:
            Executed_Gtid_Set:
                Auto_Position: 0
         Replicate_Rewrite_DB:
                 Channel_Name:
           Master_TLS_Version:
1 row in set (0.00 sec)
```
OK!



## Dump
- 現状確認
```
master
###########################################################

mysql> show databases;
+--------------------+
| Database           |
+--------------------+
| information_schema |
| mysql              |
| performance_schema |
| sys                |
| zabbix             |
+--------------------+
5 rows in set (0.00 sec)

mysql> select Host, User from mysql.user;
+------------+---------------+
| Host       | User          |
+------------+---------------+
| %          | zabbix        |
| 10.0.11.20 | repl          |
| localhost  | mysql.session |
| localhost  | mysql.sys     |
| localhost  | root          |
+------------+---------------+
5 rows in set (0.00 sec)

mysql> show master status\G
*************************** 1. row ***************************
             File: ip-10-0-21-20-bin.000002
         Position: 539634
     Binlog_Do_DB:
 Binlog_Ignore_DB:
Executed_Gtid_Set:
1 row in set (0.00 sec)


slave
###########################################################
mysql> show databases;
+--------------------+
| Database           |
+--------------------+
| information_schema |
| mysql              |
| performance_schema |
| sys                |
+--------------------+
4 rows in set (0.00 sec)

mysql> select Host, User from mysql.user;
+-----------+---------------+
| Host      | User          |
+-----------+---------------+
| localhost | mysql.session |
| localhost | mysql.sys     |
| localhost | root          |
+-----------+---------------+
3 rows in set (0.00 sec)

mysql> show slave status\G
*************************** 1. row ***************************
               Slave_IO_State: Waiting for master to send event
                  Master_Host: 10.0.21.20
                  Master_User: repl
                  Master_Port: 3306
                Connect_Retry: 60
              Master_Log_File: ip-10-0-21-20-bin.000002
          Read_Master_Log_Pos: 587412
               Relay_Log_File: ip-10-0-11-20-relay-bin.000005
                Relay_Log_Pos: 383
        Relay_Master_Log_File: ip-10-0-21-20-bin.000002
             Slave_IO_Running: Yes
            Slave_SQL_Running: No
              Replicate_Do_DB:
          Replicate_Ignore_DB:
           Replicate_Do_Table:
       Replicate_Ignore_Table:
      Replicate_Wild_Do_Table:
  Replicate_Wild_Ignore_Table:
                   Last_Errno: 1146
                   Last_Error: Error executing row event: 'Table 'zabbix.history' doesn't exist'
                 Skip_Counter: 0
          Exec_Master_Log_Pos: 154
              Relay_Log_Space: 588030
              Until_Condition: None
               Until_Log_File:
                Until_Log_Pos: 0
           Master_SSL_Allowed: No
           Master_SSL_CA_File:
           Master_SSL_CA_Path:
              Master_SSL_Cert:
            Master_SSL_Cipher:
               Master_SSL_Key:
        Seconds_Behind_Master: NULL
Master_SSL_Verify_Server_Cert: No
                Last_IO_Errno: 0
                Last_IO_Error:
               Last_SQL_Errno: 1146
               Last_SQL_Error: Error executing row event: 'Table 'zabbix.history' doesn't exist'
  Replicate_Ignore_Server_Ids:
             Master_Server_Id: 1
                  Master_UUID: 270ec95b-d7a2-11ea-b55a-0a9dc8630d08
             Master_Info_File: /var/lib/mysql/master.info
                    SQL_Delay: 0
          SQL_Remaining_Delay: NULL
      Slave_SQL_Running_State:
           Master_Retry_Count: 86400
                  Master_Bind:
      Last_IO_Error_Timestamp:
     Last_SQL_Error_Timestamp: 200807 00:59:37
               Master_SSL_Crl:
           Master_SSL_Crlpath:
           Retrieved_Gtid_Set:
            Executed_Gtid_Set:
                Auto_Position: 0
         Replicate_Rewrite_DB:
                 Channel_Name:
           Master_TLS_Version:
1 row in set (0.00 sec)
```

- master
```
$ mysqldump -h localhost -u root -p --all-databases --master-data > 20200807_dump.sql
option: http://www.tohoho-web.com/ex/mysql-mysqldump.html
```

https://www.sejuku.net/blog/82770
http://www.tohoho-web.com/ex/mysql-mysqldump.html

異なるサーバー間のMySQLデータのコピー
https://dev.mysql.com/doc/refman/5.6/ja/copying-databases.html







## Zabbix
※別のサーバーから3306ポートでアクセスするならmysqlで設定しないとconnectエラーになる。下記「%」のとこ。
```
mysql> GRANT ALL PRIVILEGES ON *.* TO root@'%' IDENTIFIED BY 'rootのpass' WITH GRANT OPTION;
```

- DB_masterでmysqlの設定
```
mysql -u root -p

<書式>
> create database <データベース名> character set utf8 collate utf8_bin;
> create user '<ユーザー名>'@'<ip,dmain,%全て>' identified by '<パスワード>';
> grant all on <データベース名>.* to '<ユーザー名>'@'<ip,dmain,%全て>';
> flush privileges;

<zabbix>
> create database zabbix character set utf8 collate utf8_bin;
> create user 'zabbix'@'%' identified by 'root';
> grant all on zabbix.* to 'zabbix'@'%';
> flush privileges;
```
- Zabbix_server側で確認
```
mysql -u zabbix -h <private_ip> -p
> OK!

sudo zcat /usr/share/doc/zabbix-server-mysql*/create.sql.gz | mysql -u zabbix -h <private_ip> -p zabbix
...
```

# 参考
https://utage.headwaters.co.jp/blog/archives/4958
https://zatoima.github.io/mysql-aws-ec2-replication.html




ex
http://www.maruko2.com/mw/MySQL_スレーブで_SQL_スレッドが停止した場合の対処方法
https://qiita.com/yamotuki/items/2d1c74c3253e9c3b0562
https://dev.mysql.com/doc/refman/5.6/ja/copying-databases.html
https://www.it-swarm.dev/ja/mysql/mysqldumpエラー1045正しいパスワードなどにもかかわらずアクセスが拒否されました/1043190719/
http://www.tohoho-web.com/ex/mysql-mysqldump.html
https://dev.mysql.com/doc/refman/5.6/ja/replication-howto-mysqldump.html

