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

if ( ngx.var.request_uri == [[/]] and resp >= 2)
then 

   resp = resp-1 --因为根路径 / 里面 index 到 /index.html 导致access_by_lua_file 脚本访问2次所以这里要减去第一次成功的从定向

end

if (resp > 1) 
then

    say_html('{"code":500,"msg":"WTF!!!接口 ['..ngx.var.request_uri..'] 3秒内相同操作访问'..resp..'次,异常访问限制"}')

end

if ( ngx.var.request_uri ~= [[/index.html]] and  ngx.var.request_uri ~= [[/]])
then 

    say_html('{"code":200,"msg":"接口 ['..ngx.var.request_uri..'] 3秒内相同操作访问'..resp..'次,正常访问"}')

end
