
module CgService
  module RakeLoader
    class << self
      def load_tasks!
        puts 'boo!'
        require 'rake'
        [:db].each do |file|
          load(File.join(File.dirname(__FILE__), "tasks/#{file.to_s}.rake"))
        end
      end
    end
  end 
end

