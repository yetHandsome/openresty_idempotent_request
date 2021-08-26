--避免 由于重定向导致 access_by_lua_file 脚本访问2次的问题
# ngx.var.uri 为重定向前地址 ngx.var.request_uri 为重定向后地址， 重定向前 ngx.var.request_uri 等于 ngx.var.uri

if( ngx.var.uri ~= ngx.var.request_uri ) then
    return
end

local redis = require "resty.redis"  --引入redis模块
local redis_key = getReqKey()

red = redis:new()  --创建一个对象，注意是用冒号调用的
--设置超时（毫秒）  
red:set_timeout(1000)
--建立连接  
local ok, err = red:connect(redis_host, redis_port)
if not ok then  
    ngx.say("connect to redis error : ", err)  
    return close_redis(red)  
end  

--连接授权的redis
ok, err = red:auth(redis_password)
if not ok then
    ngx.say("failed to auth: ", err)
    return close_redis(red)
end

--调用API设置key  
resp, err = red:incr(redis_key) 

--设置key过期时间为3秒
red:expire(redis_key,3)


if err then  
    ngx.say("set msg error : ", err)  
    return close_redis(red)  
end  


close_redis(red)

if (resp > 1) 
then

    say_html('{"code":500,"msg":"WTF!!!接口 ['..ngx.var.request_uri..'] 3秒内相同操作访问'..resp..'次,异常访问限制"}')

end

--这个只是为了演示效果而添加的，正常情况是可以去掉整段代码
if ( ngx.var.request_uri ~= [[/index.html]] and  ngx.var.request_uri ~= [[/50x.html]] and  ngx.var.request_uri ~= [[/]])
then 

    say_html('{"code":200,"msg":"接口 ['..ngx.var.request_uri..'] 3秒内相同操作访问'..resp..'次,正常访问"}')

end
