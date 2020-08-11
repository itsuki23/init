## postfix設定
```
設定されてるMTA確認
$ alternatives --display mta

postfixのバージョン・設定確認
$ rpm -qa | grep postfix
$ postconf -n

設定ファイルのオリジナルをコピー
$ sudo cp {-a or -p} /etc/postfix/main.cf /etc/postfix/main.cf.org

$ sudo vi /etc/postfix/main.cf
#myhostname = host.domain.tld
#myhostname = virtual.domain.tld
myhostname = mail.example.com
-> Linux 自身のFQDN名を記述する？
   -> メールヘッダーの経路情報やSMTP通信時のEHLOコマンドの返答値に使われる

#mydomain = domain.tld
mydomain = example.com  -> 指定しなくてもいい。myhostnameから最初の要素を引くのがdefault
-> 所属DNSドメインを記述 ※インターネット上で有効なDNSドメインであること

#myorigin = $myhostname -> ~@mail.example.com
myorigin = $mydomain    -> ~@example.com
-> 受信者アドレスがユーザー名だけの場合に自動付与するアドレスを指定

inet_interfaces = all
-> Linuxマシン自身のどのIPアドレスでメールをやり取りするか指定

inet_protcols = all
-> IPv4 と IPv6 ( 指定はipv4, ipv6 )

mydestination = $myhostname, $localhost, $mydomain, localhost, +$mydomain   -> ドメインと一致するメールも自身のボックスに格納する例
-> 指定したアドレスとメールアドレスの[@]から右側と一致したメールは、他メールサーバーに配送せず、
   このLinuxマシン自身が最終受信者としてメールボックスに格納するようになる

mynetworks = 127.0.0.0/8, 172.27.1.0/24   -> 管轄の事業オフィスやデータセンターの内部ネットワークのみを指定
-> 他サーバーまたはクライアントからのSMTP通信を受付許可するネットワークアドレスを指定
-> インターネット上のあらゆるネットワークアドレスを記述してしまうと、第三者中継サーバーとなる為注意

$ sudo postfix check   -> 構文チェック
$ sudo systemctl restart postfix

$ ss -tuan | grep :25   -> 25がListenしているか確認
```

# 参考
https://www.rem-system.com/mail-postfix01/

postfix チュートリアル
http://www.tmtm.org/postfix/tutorial/index.html