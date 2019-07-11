local typedefs = require "kong.db.schema.typedefs"

return {
  name = "my-jwt",
  fields = {
    { consumer=typedefs.no_consumer },
    { config = {
        type = "record",
        fields = {
          { key_uid_name = { type = "string", default = "uid" }, },
          { key_permission_name = { type = "string", default = "permission" }, },
          { redis_addr = { type = "string",required = true, }, },
          { redis_port = { type = "string", default = "6379" }, },
          { redis_pwd = { type = "string", required = true, }, },
    }, }, },
  },
}
