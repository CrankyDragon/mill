dgram  = require 'dgram'
events = require 'events'
bunyan = require 'bunyan'


###

###
__default_log_path = "#{__dirname}/../log/error.log" 
__default_hostname = "0.0.0.0"
__default_port     = "4444"
__default_app_name = "mill"
__default_debug    = false
class Server extends events.EventEmitter
  
  constructor: (options) ->
    options = options or {}
    
    @debug = options.debug || __default_debug
    
    @host = options.host || __default_hostname
    @port = options.port || __default_port
    
    # setup bunyan
    @app_name = options.app_name || __default_app_name
    @log_file = options.log_file || __default_log_path
    @logger   = bunyan.createLogger
      name    : __default_app_name
      streams :  [path : @log_file]
  
  ###
  * Wrapper for bunyan's logging functions
  * @param level string Either fatal, error, warn, info, debug or trace
  * @param error string Message
  ###
  log: (level, error) ->
    message = error
    switch level
      when "fatal" then @logger.fatal message
      when "error" then @logger.error message
      when "warn"  then @logger.warn message
      when "info"  then @logger.info message
      when "debug" then @logger.debug message
      when "trace" then @logger.trace message
  
  
  ###
  * Helper function used to prase the UDP message sent out by rsyslogd
  * @param string Log message from rsyslod
  ###
  parse: (message) ->
    regex = ///
      <(.*)>                      # PRI
      ([\w\d\s:]+)\s              # Timestamp
      ([\S]+)\s                   # Hostname
      ([\S]+)\s                   # APP-NAME
      (.*)                        # Message
    ///
    
    message = message.toString?() or message
    
    message_parts = message?.match? regex
    if message_parts.length < 6
      throw Error "Could not log message: #{message}"
    
    # coffeescript implictly returns the data
    data = 
      priority  : message_parts[1]
      timestamp : message_parts[2]
      hostname  : message_parts[3]
      appname   : message_parts[4].replace /:$/,'' # trim the last colon off the appname
      message   : message_parts[5]
      original  : message

  ###
  * This is where the magic happens... Creates UDP datagaram socket
  ###
  run: ->
    socket = dgram.createSocket 'udp4'
    socket.bind @port, @host, (error) =>
      @log "error", error if error
    
    socket.on "message", (message, rinfo) =>
      @log "debug", [message, rinfo] if @debug
      try
        data = @parse message 
        @emit "data", data
      catch error
        @emit "error", error
        @log "error", error

module.exports = Server