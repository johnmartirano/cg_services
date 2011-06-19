module CgLookupService
  class Entry < ActiveRecord::Base
    validates_presence_of :uri, :type_name, :version, :description
    validates_uniqueness_of :uri, :scope => [:type_name, :version],
    :message => "has already been registered for this resource type and version."
    validates_length_of :uri, :type_name, :version, :description, :maximum=>255
  end
end