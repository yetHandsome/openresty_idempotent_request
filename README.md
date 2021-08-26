##openresty 接口请求幂等处理

    1.这是一个简单的将接口幂等的处理
    

    原理非常简单：md5（URL+method+数据）为key（后续都用key表示）存活时间3秒，
    对该key incr处理，返回值小于等于1发往应用,大于1则认为重复请求了


    完整的应该还要设置一个 status，失败了的请求允许重复请求（至于允许几次自己设置吧，也不能老失败重复请求吧）
    对该key incr处理，返回值小于等于1发往应用并跟该key拼接status（后续都用status_key指带这个key）设置为处理中，
    如果大于等于1则查询status_key是处理中还是失败还是成功，
    处理中或者成功了直接返回重复请求了，
    状态是失败了则把status改为处理中，发往应用，应用如果处理完成http状态为200那么，
    nginx的lua设置redis的status为OK，其它值设置status为失败。这样业务代码就无需任何改造了

    目前只做了重复请求的检测，status 那部分还没有做,md5也还为实现

    2.其实一些框架都是利用一个一次性token,在请求表单的时候埋入表单，提交的时候删除，再次提交查询没有这个token就不允许提交来限制
    
    1的优势：无须埋入token,直接根据是否同一个接口且相同参数来限制，当然还能加入标识用户的字段，根据自己项目自行修改
    1的劣势：这是一个只能限制一些用户误操作2次，或者js 底层封装，没有响应认为请求失败，结果请求2次的行为
    如果有人知道了是基于 URL+method+数据 ，他恶意破坏可以URL加一个随机数，这个就不如 一次性token 安全
    

###用途：
    	
	防止一个接口并发请求2次


###使用说明：

    使用的是官方openresty/1.19.9.1 这个版本的镜像
    
    由于这个镜像里面使用lua 会出现找不到 lua 的错误，所以要在启动前软连接

    看docker-compose.yaml openresty 的默认启动指令已经被覆盖了
    
    command:
        - sh
        - -c 
        - |
            #解决openresty 找不到lua扩展问题
            ln -sf /usr/local/openresty/lualib/resty /etc/nginx/lua/resty &
            /usr/bin/openresty -g "daemon off;"
    
    这个镜像的默认nginx.conf 要添加下面几行

    lua_package_path "/etc/nginx/lua/?.lua";
    init_by_lua_file  /etc/nginx/lua/init.lua; 
    access_by_lua_file /etc/nginx/lua/run.lua;
    
    #这个是启动docker 内部的dns 这样lua 就能直接通过容器名找到redis 而不用ip
    resolver 127.0.0.11 ipv6=off; 
    
    

###配置文件详细说明：

    redis_host="redis-server" 这个直接跟docker-compose 里面定义的 redis 服务的服务名称一致即可 （services 下面定义的服务 或者该服务的 hostname 一致即可）
    redis_port=6379
    redis_password="test123" 这个跟 docker-compose 里面定义的 redis 密码一致即可 --requirepass test123
    redis_key_prefix="ri:" 这个是key前缀，避免跟其它业务冲突，这个自行根据需求修改即可



###规则更新：

    /usr/bin/openresty -s reload 即可生效

###一些说明：

    启动项目 在 docker-compose.yaml 的同级目录执行
    docker-compose up -d 即可 如果是测试 可以 去掉 -d  查看到一些报错原因
    访问本地的 http://localhost:8084 查看效果
    8084 端口是 docker-compose.yaml 定义的 这个可以根据自己情况进行更改

    这个项目是对所有请求一律 过滤 3秒内只能请求1次，这个感觉不太好，
    因为有时一个 GET 请求可能，展示列表一次请求，删除某条记录，再次请求，可能短时间请求2次，
    可以基于 method 更改，GET 请求一律不限制，其它请求 根据 URL+method+数据 限制 相同数据只能3秒内请求一次
    这样更改后就需要后端自行定义那些接口是需要幂等的就设为POSE,不需要幂等的就设为 GET 请求，而无须
    
    redis 可以改成连接池模式 自行参考 https://www.cnblogs.com/reblue520/p/11434278.html