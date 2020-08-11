---------------------------------------------------------
# Chrony
---------------------------------------------------------
- 時刻同期すべし
https://public-constructor.com/ec2-amazon-linux2-timezone/

---------------------------------------------------------
# Host
---------------------------------------------------------
- Attached Template
   (ex) OS Linux
#### application
```s
CPU	                                    アイテム 15
Filesystems	                            アイテム
General                                     アイテム 5
Memory                                      アイテム 5
Network interfaces	                    アイテム
OS	                                    アイテム 8
Performance	                            アイテム 15
Processes	                            アイテム 2
Security	                            アイテム 2
Template App Zabbix Agent: Zabbix agent	    アイテム 3
```

#### item
Agentはconfファイルの
RefreshActiveChecksの間隔でServerにアイテムリストを問い合わせる。

キーと戻り値 ドキュメント
https://www.zabbix.com/documentation/2.2/jp/manual/config/items/itemtypes/zabbix_agent
```s
base 	
監視間隔  ヒストリ  トレンド  タイプ
1m       1w       365d    Zabbixエージェント

Processor load (5 min average per core)		                   
system.cpu.load[percpu,avg5]	  
CPU, Performance

Processor load (15 min average per core)		               
system.cpu.load[percpu,avg15]  
CPU, Performance

Context switches per second		                               
system.cpu.switches	          
CPU, Performance

CPU interrupt time		                                       
system.cpu.util[,interrupt]	  
CPU, Performance

CPU softirq time		                                       
system.cpu.util[,softirq]	  
CPU, Performance

CPU guest nice time		                                       
system.cpu.util[,guest_nice]	  
CPU, Performance

CPU steal time		                                           
system.cpu.util[,steal]	      
CPU, Performance

Interrupts per second		                                   
system.cpu.intr	              
CPU, Performance

Available memory	                                           
vm.memory.size[available]	  
Memory

CPU nice time		                                           
system.cpu.util[,nice]	      
CPU, Performance

CPU system time		                                           
system.cpu.util[,system]	      
CPU, Performance

CPU iowait time	                                               
system.cpu.util[,iowait]	      
CPU, Performance

CPU user time		                                           
system.cpu.util[,user]	      
CPU, Performance

CPU idle time		                                           
system.cpu.util[,idle]	      
CPU, Performance

Free swap space in %                                           
system.swap.size[,pfree]	      
Memory

Host local time		                                           
system.localtime	              
General, OS	

CPU guest time		                                           
system.cpu.util[,guest]	      
CPU, Performance

Template App Zabbix Agent: Zabbix agent ping	               
agent.ping	                  
Zabbix agent

Processor load (1 min average per core)	     	               
system.cpu.load[percpu,avg1]	  
CPU, Performance

Number of running processes	                	               
proc.num[,,run]	              
Processes

Number of processes	                                           
proc.num[]	                  
Processes

Free swap space		                                           
system.swap.size[,free]	      
Memory

Number of logged in users		                               
system.users.num	              
OS, Security	

System uptime                                                  
system.uptime	              
General, OS	

Host boot time		                                           
system.boottime	              
General, OS	

Total memory		                                           
vm.memory.size[total]	      
Memory	

Checksum of /etc/passwd	                                       
vfs.file.cksum[/etc/passwd]	  
Security	

Template App Zabbix Agent: Host name of Zabbix agent running   
agent.hostname	              
Zabbix agent	

Total swap space		                                       
system.swap.size[,total]	      
Memory	

System information	                                           
system.uname	                  
General,

Template App Zabbix Agent: Version of Zabbix agent running     
agent.version	              
Zabbix agent

Host name	        	                                       
system.hostname	              
General, OS

Maximum number of opened files	                               
kernel.maxfiles	              
OS

Maximum number of processes		                               
kernel.maxproc	              
OS
```

#### triger
関数
https://www.zabbix.com/documentation/2.2/jp/manual/appendix/triggers/functions
```s
警告    /etc/passwd has been changed on {HOST.NAME}	                                        
       {Template OS Linux:vfs.file.cksum[/etc/passwd].diff(0)}>0  	

情報    Configured max number of opened files is too low on {HOST.NAME}	                    
       {Template OS Linux:kernel.maxfiles.last(0)}<1024	       	

情報    Configured max number of processes is too low on {HOST.NAME}	                    
       {Template OS Linux:kernel.maxproc.last(0)}<256	           	

警告    Disk I/O is overloaded on {HOST.NAME}	                                            
       {Template OS Linux:system.cpu.util[,iowait].avg(5m)}>20	   	

情報    Host information was changed on {HOST.NAME}	                                        
       {Template OS Linux:system.uname.diff(0)}>0	               	

情報    Template App Zabbix Agent: Host name of Zabbix agent was changed on {HOST.NAME}	    
       {Template OS Linux:agent.hostname.diff(0)}>0	           	

情報    Hostname was changed on {HOST.NAME}	                                                
       {Template OS Linux:system.hostname.diff(0)}>0	           	

軽度    Lack of available memory on server {HOST.NAME}	                                    
       {Template OS Linux:vm.memory.size[available].last(0)}<20M	

警告    Lack of free swap space on {HOST.NAME}	                                            
       {Template OS Linux:system.swap.size[,pfree].last(0)}<50	   	

警告    Processor load is too high on {HOST.NAME}	                                        
       {Template OS Linux:system.cpu.load[percpu,avg1].avg(5m)}>5	

警告    Too many processes on {HOST.NAME}	                                                
       {Template OS Linux:proc.num[].avg(5m)}>300	               	

警告    Too many processes running on {HOST.NAME}	                                        
       {Template OS Linux:proc.num[,,run].avg(5m)}>30	           	

情報    Template App Zabbix Agent: Version of Zabbix agent was changed on {HOST.NAME}	    
       {Template OS Linux:agent.version.diff(0)}>0	               	

軽度    Template App Zabbix Agent: Zabbix agent on {HOST.NAME} is unreachable for 5 minutes	
       {Template OS Linux:agent.ping.nodata(5m)}=1	               	

情報    {HOST.NAME} has just been restarted	                                                
       {Template OS Linux:system.uptime.change(0)}<0
```
他のテンプレート
(ex)Ping
```
<triger>
High ICMP ping loss           {Template Module ICMP Ping:icmppingloss.min(5m)}>{$ICMP_LOSS_WARN} and {Template Module ICMP Ping:icmppingloss.min(5m)}<100
High ICMP ping response time  {Template Module ICMP Ping:icmppingsec.avg(5m)}>{$ICMP_RESPONSE_TIME_WARN}
Unavailable by ICMP ping      {Template Module ICMP Ping:icmpping.max(#3)}=0
```
#### graph

#### screen

#### discovery rule

#### web scenario
https://www.walbrix.co.jp/blog/2014-02-zabbix-simple-web-monitoring.html

#### 保存前処理
データを成形してデータベースに保存

---------------------------------------------------------
# Action
---------------------------------------------------------
- 実行内容
- 復旧時の実行内容
- 更新時の実行内容

```
- 実行内容

件名
Problem: {EVENT.NAME}

メッセージ
Problem started at {EVENT.TIME} on {EVENT.DATE}
Problem name: {EVENT.NAME}
Host: {HOST.NAME}
Severity: {EVENT.SEVERITY}

Original problem ID: {EVENT.ID}
{TRIGGER.URL}
```
```
- 復旧時の実行内容

Resolved: {EVENT.NAME}

Problem has been resolved at {EVENT.RECOVERY.TIME} on {EVENT.RECOVERY.DATE}
Problem name: {EVENT.NAME}
Host: {HOST.NAME}
Severity: {EVENT.SEVERITY}

Original problem ID: {EVENT.ID}
{TRIGGER.URL}
```
```
- 更新時の実行内容

Updated problem: {EVENT.NAME}

{USER.FULLNAME} {EVENT.UPDATE.ACTION} problem at {EVENT.UPDATE.DATE} {EVENT.UPDATE.TIME}.
{EVENT.UPDATE.MESSAGE}

Current problem status is {EVENT.STATUS}, acknowledged: {EVENT.ACK.STATUS}.
```
