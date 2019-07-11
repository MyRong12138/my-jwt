# my-jwt
按照公司要求编写的一个kong自定义插件，实现解析jwt，然后查询redis数据库验证身份，最后将解析参数放入header传入上游服务器
# 添加插件
进入/usr/local/share/lua/5.1/kong，找到constants.lua文件，在文件上添加自定义插件名change-url，然后就可以通过名称直接添加了。
## 插件参数说明
* *config.key_uid_name*
  + jwt解析负载数据 用户id名称<br>
* *config.key_permission_name*
  + jwt解析负载数据 用户权限名称<br>
* *config.redis_addr*
  + redis数据库地址
* *config.redis_port*
  + redis数据库端口号
* *config.redis_pwd*
  + redis数据库密码
