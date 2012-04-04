require 'yard'  # must come before activesupport is loaded to avoid 'require' override oddness
require 'tmpdir'

module CgService
  # Include this module and set class attribute 'auto_doc_file'.
  # to the absolute path of the file that should be parsed.
  #
  # class SomeClass
  #   include AutoDoc
  #   self.auto_doc_file = File.expand_path(__FILE__)
  # end
  #
  # The returned documentation will be for the class 'self' (the class
  # including AutoDoc).
  module AutoDoc
    class SinatraDSLHandler < YARD::Handlers::Ruby::Base
      handles method_call(:get)
      handles method_call(:post)
      handles method_call(:put)
      handles method_call(:delete)

      # to make the documentation order match the source code order
      @@order = 0

      def process
        arg0 = statement.parameters.first.jump(:tstring_content, :ident).source
        
        # truncate trailing /? and optional $
        url = (arg0 =~ %r{(/.*)/\?\$?$}) ? $1 : arg0
        
        http_method = statement.method_name.jump(:ident).source

        path = http_method + url # unique path for this code object
        object = YARD::CodeObjects::MethodObject.new(namespace, path)
        register(object)

        object.dynamic = true
        object[:url] = url
        object[:http_method] = http_method
        object[:sort_order] = @@order
        @@order += 1
      end
    end

    def self.included(receiver)
      receiver.class.send(:attr_accessor, :auto_doc_file)
    end

    # Get the documentation for this class as HTML.  Documentation is
    # specific to Sinatra services and only includes URL
    # documentation.  Documentation is parsed and rendered once and
    # then cached.
    def documentation_html
      @documentation_html ||= generate_documentation_html
    end

    private

    # Render the YARD documentation for the current class, using the cg_service templates
    def generate_documentation_html
      YARD::Registry.yardoc_file = Dir.mktmpdir('auto_yardoc')
      begin
        YARD::Tags::Library.define_tag('', :request_param, :with_types_and_name)
        YARD::Tags::Library.define_tag('', :request_body, :with_types_and_name)
        YARD::Registry.load([settings.app_file], true)
        template_path = File.join(File.dirname(__FILE__), '../../templates_custom')
        YARD::Templates::Engine.register_template_path(template_path)
        YARD::Templates::Engine.render(:object => YARD::Registry.resolve(nil, self.class.to_s),
                                       :format => :html)
      ensure
        YARD::Registry.delete_from_disk
      end
    end
  end
end

