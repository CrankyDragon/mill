Server = require "#{__dirname}/src/server"
config = require "#{__dirname}/etc/mill.conf"
cradle = require 'cradle' 

connection = new cradle.Connection 
  host : config.db.host
  port : config.db.port
  cache : config.db.cache
  raw   : config.db.raw
  
db = connection.database config.db.database
db.create()

daemon = new Server debug: true
daemon.on "data", (data) =>
  db.exists (err, exists) =>
    if err
      daemon.log "info", "Could not log message: #{data.original}"
      return daemon.log "error", err

    if not exists
      db.create()
      daemon.log "info", "creating database #{config.db.database}"
    
    db.save data, (err, res) =>
      daemon.log "debug", [err, res] if daemon.debug
      return daemon.log "error", err if err
      
daemon.run()