class Log4jLogger
  require 'log4j-1.2.15.jar'
  L4JLevel = org.apache.log4j.Level

  DEBUG	=	"DEBUG"
  INFO	=	"INFO"
  WARN	=	"WARN"
  ERROR	=	"ERROR"
  FATAL	=	"FATAL"
  UNKNOWN	=	"UNKNOWN"

  SEVERETIES = {
      DEBUG => L4JLevel::DEBUG,
      INFO => L4JLevel::INFO,
      WARN => L4JLevel::WARN,
      ERROR => L4JLevel::ERROR,
      FATAL => L4JLevel::FATAL,
  }
  INVERSE = SEVERETIES.invert

  def initialize(config_file)
    org.apache.log4j.PropertyConfigurator.configure(config_file)
    @logger = org.apache.log4j.Logger.getRootLogger  #Can be any specific logger pathname
    @root = org.apache.log4j.Logger.getRootLogger
  end

  def add(severity, message = nil, progname = nil, &block)
    message = (message || (block && block.call) || progname).to_s
    @logger.log(SEVERETIES[severity], message)
  end

  def level
    INVERSE[@logger.getEffectiveLevel]
  end

  def level=(level)
    raise "Invalid log level" unless SEVERETIES[level]
    @root.setLevel(SEVERETIES[level])
  end

  def enabled_for?(severity)
    @logger.isEnabledFor(SEVERETIES[severity])
  end

  #Lifted from BufferedLogger
  for severity in SEVERETIES.keys
    class_eval <<-EOT, __FILE__, __LINE__
      def #{severity.downcase}(message = nil, progname = nil, &block)  # def debug(message = nil, progname = nil, &block)
        add(#{severity}, message, progname, &block)                    #   add(DEBUG, message, progname, &block)
      end                                                              # end
                                                                       #
      def #{severity.downcase}?                                        # def debug?
        enabled_for?(#{severity})                                           #   DEBUG >= @level
      end                                                              # end
    EOT
  end

  def method_missing(meth, *args)
    puts "UNSUPPORTED METHOD CALLED: #{meth}"
  end
end