local http = require "socket.http"
local ltn12 = require "ltn12"
local cjson = require "cjson.safe"
local jwt_decoder = require "kong.plugins.jwt.jwt_parser"
local req_set_header = ngx.req.set_header
local BasePlugin = require "kong.plugins.base_plugin"

local kong = kong

local TokenAuthHandler = BasePlugin:extend()

TokenAuthHandler.PRIORITY = 1000
TokenAuthHandler.VERSION="0.1.0"

local KEY_PREFIX = "whispir_auth_token"
local EXPIRES_ERR = "token expires"

local function extract_token(request)
  local auth_header = request.get_headers()["authorization"]
  if auth_header then
    local iterator, ierr = ngx.re.gmatch(auth_header, "\\s*[Bb]earer\\s+(.+)")
    if not iterator then
      return nil, ierr
    end
    
    local m, err = iterator()
    if err then
      return nil, err
    end
    
    if m and #m > 0 then
      return m[1]
    end
  end
end

local function test_redis(conf,setName,setValue)
  local redis = require "resty.redis";
  local red = redis:new();
 
  red:set_timeout(redis_connection_timeout);-- Time out
 
  local ok, err = red:connect(conf.redis_addr, conf.redis_port);
  ok, err = red:auth(conf.redis_pwd)-- password    
  if not ok then    
      --ngx.log(ngx.DEBUG, "error:" .. err);
        return kong.response.exit(500, { message = "Unable to connect to the database:"..tostring(err)})
  else
	  local blackValue, err = red:sismember(setName,setValue);
	  if err then    
		--ngx.log(ngx.DEBUG, "error:" .. err)
            return kong.response.exit(500, { message = tostring(err) })
	  else
		return blackValue
	  end
  end
end

local function query_and_validate_token(token, conf)
---[[
  local request_uri = ngx.var.request_uri
  if false then
  return kong.response.exit(401, { message = tostring(request_uri) })
  end
--]]

---[[
  local jwt, err = jwt_decoder:new(token)
  if err then
      return kong.response.exit(401, { message = tostring(err) })
  end

  local claims = jwt.claims
  local header = jwt.header

  local jwt_uid_key = claims[conf.key_uid_name] or header[conf.key_uid_name]
  local jwt_permission_key = claims[conf.key_permission_name] or header[conf.key_permission_name]
  if not jwt_uid_key then
    return false, { status = 401, message = "No mandatory '" .. conf.key_uid_name .. "' in claims" }
  end

  if not jwt_permission_key then
    return false, { status = 401, message = "No mandatory '" .. conf.key_permission_name .. "' in claims" }
  end
--return kong.response.exit(500, { message = jwt_permission_key  })

---[[
  --test Redis

  local blackValue=test_redis(conf,jwt_uid_key,jwt_permission_key)

  if (tostring(blackValue)~="1") then
  return kong.response.exit(401, { message = "Wrong request,no permission:"..tostring(blackValue)})
  end
  --test end
---[[

  local authorization = tostring(jwt_uid_key);
  local authorizationBase64 = ngx.encode_base64(authorization);
  local authorizationHeader = "Basic " .. authorizationBase64;
  req_set_header("uid", authorization)
  print(authorization)
--]]

end

function TokenAuthHandler:new()
  TokenAuthHandler.super.new(self, "my-jwt")
end

function TokenAuthHandler:access(conf)
  TokenAuthHandler.super.access(self)
  
  local token, err = extract_token(ngx.req)
  if err then
    ngx.log(ngx.ERR, "failed to extract token: ", err)
    return kong.response.exit(500, { message = err })
  end
  ngx.log(ngx.DEBUG, "extracted token: ", token)
  
  local ttype = type(token)
  if ttype ~= "string" then
    if ttype == "nil" then
      return kong.response.exit(401, { message = "Missing token" })
    end
    if ttype == "table" then
      return kong.response.exit(401, { message = "Multiple tokens" })
    end
    return kong.response.exit(401, { message = "Unrecognized token" })
  end
  
  local info
  info, err =  query_and_validate_token(token, conf)
  
  if err then
    ngx.log(ngx.ERR, "failed to validate token: ", err)
    if EXPIRES_ERR == err then
      return kong.response.exit(401, { message = EXPIRES_ERR })
    end
    return kong.response.exit(500, { message = err })
  end
  
  --if info.expires_at < os.time() then
    --return kong.response.exit(401, { message = EXPIRES_ERR })
  --end
  --ngx.log(ngx.DEBUG, "token will expire in ", info.expires_at - os.time(), " seconds")

end

return TokenAuthHandler
