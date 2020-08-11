# MySQLレプリケーションとダンプ
```
<AWS>
EC2_01: zabbix server  10.0.20.20
EC2_02: mysql master   10.0.21.20
EC2_03: mysql slave    10.0.11.20

zabbix 4.0
mysql  5.7
```

# レプリケーション


#### 作業フロー
```
step1
  master: ① binary log on!  ② set id
  slave : ③ set id

step2
  master: ④ create user for slave  ⑤ check binary log & position
  slave : ⑥ master setting
```

#### ファイル設定
[master]
```
$ sudo vi etc/my.cnf
  [mysqld]
  log-bin 
  server-id=1

$ systemctl restart mysqld
```

[slave]
```
$ sudo vi etc/my.cnf
  [mysqld]
  server-id=2

$ systemctl restart mysqld
```

#### SQL設定
[master]
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

[slave]
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

Slave_IO_Running: Yes、Slave_SQL_Running: Yesだったら設定OK!
つまり上記NG。

疎通確認
```
$ curl -vv telnet://10.0.21.20:3306 --output /dev/null
```
ネットワーク関係ならAWS側の設定を確認。今回はセキュリティでのインバウンド設定に不備。
もう一度疎通確認してOKなら、再度statusコマンド再度実行。


```
> show slave status\G
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
マスターでテーブル作成をして、スレーブにもレプリケートされてたら問題なし。






# ダンプ

#### 作業フロー
```
slaveを停止。(略)
zabbixとmasterで通常設定。(略)
zabbix停止。(略)

Dump設定。(ここから！)
masterのzabbixテーブルをslaveにインポート。
zabbix起動。

確認。
```
[zabbix設定](#anchor1)


#### スレーブSQL設定(マスターからのSQLアクセスを許可)
```
スレーブ
> create user 'master_for_dump'@'10.0.21.20' identified by 'password';
> grant all on *.* to 'master_for_dump'@'10.0.21.20';
> flush privileges;

マスター
$ mysql -u master_for_dump -p -h 10.0.11.20
> OK! 一旦exit
```

#### Dump実装
```
<読み込み停止>
マスター
> FLUSH TABLES WITH READ LOCK;

<スレーブにデータベース作成後、データベースDump、マスターのデータベース内容をスレーブへエクスポート>
マスター
$ mysqladmin -u master_for_dump -p -h 10.0.11.20 create zabbix    ①チェック
$ mysqldump -h localhost -u root -p --databases zabbix > ./zabbix_dump.sql
$ mysql -u master_for_dump -p -h 10.0.11.20 < ./zabbix_dump.sql   ②チェック
--------------------------------------------------------------------
随時チェック
マスター> show databases; use zabbix; show tables;
スレーブ> ①show databases; use zabbix; ②show tables;
--------------------------------------------------------------------

<読み込み停止を解除>
mysql> UNLOCK TABLES;
```

#### zabbix起動（略）
#### 確認
```
スレーブ
mysql> show slave status\G
*************************** 1. row ***************************
               Slave_IO_State: Waiting for master to send event
                  Master_Host: 10.0.21.20
                  Master_User: repl
                  Master_Port: 3306
                Connect_Retry: 60
              Master_Log_File: ip-10-0-21-20-bin.000002
          Read_Master_Log_Pos: 1099051
               Relay_Log_File: ip-10-0-11-20-relay-bin.000007
                Relay_Log_Pos: 98583
        Relay_Master_Log_File: ip-10-0-21-20-bin.000002
             Slave_IO_Running: Yes
            Slave_SQL_Running: Yes
                               ...
```
今回は手順ミスでコンフリクトが起きたので、
以下参考欄「ダンプ後のエラー処理」を参考に対処。解決。
確認として、マスター側でテーブル作成。スレーブ側でも作成されていれば問題なし。




# 参考
#### MySQL
基本インストール方法
https://qiita.com/2no553/items/952dbb8df9a228195189

パスワード変更(テスト用)
https://qiita.com/RyochanUedasan/items/9a49309019475536d22a

#### レプリケーション
ドキュメント
https://dev.mysql.com/doc/refman/5.6/ja/replication.html
その他
https://utage.headwaters.co.jp/blog/archives/4958
https://zatoima.github.io/mysql-aws-ec2-replication.html

MySQLのbinlog設定値
https://shiro-16.hatenablog.com/entry/2016/06/12/154343

#### ダンプ
MySQL データベースのほかのマシンへのコピー
https://dev.mysql.com/doc/refman/5.6/ja/copying-databases.html
ダンプ後のエラー処理
http://www.maruko2.com/mw/MySQL_スレーブで_SQL_スレッドが停止した場合の対処方法
バックアップ・リストア
http://www.tohoho-web.com/ex/mysql-mysqldump.html
その他
https://www.sejuku.net/blog/82770

#### 今後リサーチ
zabbixによるmysqlレプリケーション監視設定
https://blog.apar.jp/zabbix/3218/

Dumpするファイル形式は .db? .sql? 今回は.sqlで対応。
https://dev.mysql.com/doc/refman/5.6/ja/replication-howto-mysqldump.html



# メモ
#### Zabbix  <a id="anchor1"></a>
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
- メモ。db_master_server側で以下の設定してもいい。dbアクセスが後々楽に。
```
db_server_mysql> GRANT ALL PRIVILEGES ON *.* TO root@'%' IDENTIFIED BY 'rootのpass' WITH GRANT OPTION;

上記「%」のとこ。
```
