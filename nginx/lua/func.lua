

---定义 redis关闭连接的方法
function close_redis(red)  
    if not red then  
        return  
    end  
    local ok, err = red:close()  
    if not ok then  
        ngx.say("close redis error : ", err)  
    end  
end



function getReqKey()
    ngx.req.read_body()
    postargs = TableToStr(ngx.req.get_post_args())
    all = redis_key_prefix.."_"..ngx.var.http_host.."_"..ngx.var.request_uri.."_"..ngx.var.request_method.."_"..postargs;
    res = md5str(all)
    return res
end

function md5str(s)
    --md5 = require "resty.md5"  --引入 /usr/local/openresty/lualib/resty/md5.lua
    --return md5.sumhexa(s)
    return s
end

function tableToStr(args)
    all_str = ''
    for key, val in pairs(args) do
        if type(val) == "table" then
            all_str = all_str..'k:'..key..'=>v:'..tableTostr(val)..'&'
        else
            all_str = all_str..'k:'..key..'=>v:'..val..'&'
        end
    end
    return all_str
end




function getClientIp()
    IP  = ngx.var.remote_addr 
    if IP == nil then
            IP  = "unknown"
    end
    return IP
end

function say_html(html)
    
    ngx.header.content_type = "text/html"
    ngx.status = ngx.HTTP_OK
    ngx.say(html)
    ngx.exit(ngx.status)
    
end

function say_json(json)
    
    ngx.header.content_type = "application/json"
    ngx.status = ngx.HTTP_OK
    ngx.say(json)
    ngx.exit(ngx.status)
    
end






function ToStringEx(value)
    if type(value)=='table' then
       return TableToStr(value)
    elseif type(value)=='string' then
        return "\'"..value.."\'"
    else
       return tostring(value)
    end
end

function TableToStr(t)
    if t == nil then return "" end
    local retstr= "{"

    local i = 1
    for key,value in pairs(t) do
        local signal = ","
        if i==1 then
          signal = ""
        end

        if key == i then
            retstr = retstr..signal..ToStringEx(value)
        else
            if type(key)=='number' or type(key) == 'string' then
                retstr = retstr..signal..'['..ToStringEx(key).."]="..ToStringEx(value)
            else
                if type(key)=='userdata' then
                    retstr = retstr..signal.."*s"..TableToStr(getmetatable(key)).."*e".."="..ToStringEx(value)
                else
                    retstr = retstr..signal..key.."="..ToStringEx(value)
                end
            end
        end

        i = i+1
    end

     retstr = retstr.."}"
     return retstr
end

function StrToTable(str)
    if str == nil or type(str) ~= "string" then
        return
    end
    
    return loadstring("return " .. str)()
end

function write(logfile,msg)
    local fd = io.open(logfile,"ab")
    if fd == nil then return end
    fd:write(msg)
    fd:flush()
    fd:close()
end