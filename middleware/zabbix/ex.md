手順
```
・監視項目を洗い出す。
・監視項目のkeyを洗い出す。ない場合はUserParameterなどで定義。
・ZabbixServerもしくはproxyからのzabbix_getコマンドで値取得を確認。
・ZabbixWebでアイテムの設定。値を取得できることを確認。
・トリガーを設定。テストアラートを発報してみる。
```

整理
```
Template(ミドルウェア、アプリ)
 │  │
 │  ├── item
 │  │    │ └── triger ── action
 │  │    │ 
 │  │    └──── graph/map/screen/dashbord
 │  │
 │  └── web
 │
 ↓
Host
```

洗い出し
```
<Template>
Web_nginx
DB_mysql_master
DB_mysql_slave

defaultでLinux OSテンプレートも設定

---

<Web_nginx>
item:
    Resource    (CPU,LoadAverage,Memory,Disk)
    Proccess    (sshd,nginx,zabbix-agent,docker)
    Port        (20,80,10050)
    Log         (zabbix_agent,nginx)
    TimeSync    ()

Web_Scenario:
    http://...

<DB_mysql_master>
item:
    Resource    (CPU,LoadAverage,Memory,Disk)
    Proccess    (sshd,mysql,zabbix-agent)
    Port        (20,3306,10050)
    Log         (zabbix_agent,mysql)
    Replication (master status)
    TimeSync    ()

<DB_mysql_slave>
item:
    Resource    (CPU,LoadAverage,Memory,Disk)
    Proccess    (sshd,mysql,zabbix-agent)
    Port        (20,3306,10050)
    Log         (zabbix_agent,mysql)
    Replication (slave status)
    TimeSync    ()
```

-----------------------------------------
# 死活監視
-----------------------------------------
## リソース監視
##### CPU, ロードアベレージ, メモリ, ディスク使用率
```
<CPU>
$ vmstatコマンドで監視すべき項目を確認       https://densan-hoshigumi.com/server/zabbix-linux-cpu-monitoring
procs   ------cpu-----  -----------memory----------  ---swap--  -----io----  -system-- 
 r  b   us sy id wa st    swpd   free   buff  cache    si   so     bi    bo    in   cs 
 0  0    0  0 99  0  0       0 268512   2088 341032     0    0      9   142   101  176  

item  : system.cpu.util[,user]
triger: 障害の条件式 {Template OS Linux:system.cpu.util[,user].last(#3)}>=90
        復旧の条件式 {Template OS Linux:system.cpu.util[,user].last(#3)}<80

<ロードアベレージ>
item  : key: system.cpu.load[,avg1]     => データ型は浮動小数点。1分(avg1)、5分(avg5)、15分(avg15)から選択できる
triger: {A_Template_OS_Linux:system.cpu.load[,avg1].last()}>2

<メモリ>
item  : vm.memory.size[free]            https://it-study.info/network/zabbix/zabbix-monitoring-memory/
        system.swap.size[,free]
triger: 障害の条件式 {Template OS Linux:vm.memory.size[free].last(#3)}>=90
        復旧の条件式 {Template OS Linux:vm.memory.size[free].last(#3)}<80

<ディスク使用率>
item  : vfs.fs.size[/,pused]
triger: {Template OS Linux:vfs.fs.size[/,pused].last(0)}>80
```

## プロセス監視
##### sshd、zabbix-agent、ミドルなど
```
item  : proc.num[sshd] , proc.num[zabbix-agent] , proc.num[mysql] , proc.num[nginx]
triger: 
```
## ポート監視
##### sshd、zabbix-agent、ミドルなど
```
・net.tcp.listen[port]
・net.udp.listen[port]
　　「netstat -an」の結果からLISTEN状態であるかどうか評価する事と同等。

・net.tcp.port[<ip>,port]
　　指定されたポートへTCPレベルでの接続を行う。
　　「telnet localhost 80」と同様。但し、接続できたことだけで判断。
　　尚、ここでのIPの指定は外部へアクセスするわけでは無い。
　　1サーバ内に複数インターフェース(IPアドレス)がある環境でどのインターフェースか指定する場合に使用する。
```

## サービス接続監視
```
・net.tcp.service[service,<ip>,<port>]
　　（service：ssh, ntp, ldap, smtp, ftp, http, pop, nntp, imap, tcp, https, telnet）
・net.tcp.service.perf[service,<ip>,<port>]
　　（service：ssh, ntp, ldap, smtp, ftp, http, pop, nntp, imap, tcp, https, telnet）
・net.tcp.dns[<ip>,zone]
　　⇒v2.2～　net.dns[<ip>,zone,<type>,<timeout>,<count>]
・net.tcp.dns.query[<ip>,zone,]
　　⇒v2.2～　net.dns.record[<ip>,zone,<type>,<timeout>,<count>]

　　それぞれのプロトコルレベルでの通信を行い、正常性を判断する。
　　TCP/IPの階層モデルで言うと、net.tcp.portはトランスポート層（レイヤー4）、
　　net.tcp.service、net.tcp.dnsはアプリケーション層（レイヤー5)でのチェックになる。
```

## Web監視
```
・Webシナリオ監視
　　”監視サーバから”接続確認を行う。
　　複数ページを横断してアクセスしてチェック出来る。
　　認証が必要なサイトであっても、標準認証、または標準的なPOPによるチェックであれば認証をパスしてチェックが出来る。

・web.page.get[host,<path>,<port>]
・web.page.perf[host,<path>,<port>]
・web.page.regexp[host,<path>,<port>,<regexp>,<length>,<output>]
　　Webサイトへの接続チェックを行う。
　　シナリオ監視は行えないが、エージェントから直接httpサイトへチェックを行うことが出来る。
　　（DMZ内にあるWebサーバのサイトチェックを行う場合、監視サーバ<=>監視対象サーバ間でhttp(s)ポートを開けなくても良い）
```

## ログ監視
##### たとえば、mysqlのログとか
```
/etc/my.cnfで確認

errorログ
SlowQueryログ
詳細ログ
バイナリログ
debugログ
```

-----------------------------------------
# その他
-----------------------------------------
##### ファイルが存在するか。しなかったらアラート
```
zabbix_agentd.conf/
AllowRoot=1          # セキュリティ上ダメなら https://tech-mmmm.blogspot.com/2018/03/zabbixallowroot1varlogmessages.html

zabbix_web/
item   : vfs.file.exists[/home/ec2-user/msp/check.txt]
triger : {Zabbix agent:vfs.file.exists[/home/ec2-user/msp/check.txt].last()}=0
```

##### logの中にerrorの文字が出てきたらアラート
```
zabbix_web/
item   : log[/var/log/zabbix/test.log]  ※type: Agent(active), data: log, application: none
triger : (({Zabbix agent:log[/var/log/zabbix/test.log].regexp(error)})<>0) →GUI作成
```

##### Dockerのversionを出力
```
zabbix_agentd.conf/
EnableRemoteCommands=1                       # コマンドの実行を許可（デフォルト: disabled）
UserParameter=docker.ver,/usr/bin/docker -v  # 実行するコマンド（キー,コマンド）

zabbix_web/
item   : docker.ver
```

##### 時刻同期できてるか
```
Linux/
まずは日本時間に設定  https://public-constructor.com/ec2-amazon-linux2-timezone/

zabbix_web/
item: {Template OS Linux:system.localtime.fuzzytime(30)}=0
      
# 確認は「=1」として同期してたらエラーを出す  # Server全てに関係するのでTemplate指定
```

##### Web外形監視
```
web_sg/
inbound: web側のsgでzabbixサーバーからの80アクセスを許可

zabbix_web/
web scenario: http://<web_ip:port>指定 
triger      : {Zabbix agent:web.test.fail[<Web_scenario_name>].last()}>0  -> 問題がな買ったら0が返ってくるので
```

##### MySQLレプリケーション監視
参考 https://blog.apar.jp/zabbix/3218/ ★
```
・監視項目をマスター/スレーブで決める
・エージェント用MySQLユーザー作成
・エージェントがログインするためのパスワードファイル作成
・agent.confファイル編集
・マスター/スレーブ/zabbix_serverのそれぞれで値が取れるか確認

zabbix_web/
item   : mysql.slave.status[Slave_IO_Running]
triger : {<Template_name>:mysql.slave.status[Slave_IO_Running].regexp(Yes)}=0
```


