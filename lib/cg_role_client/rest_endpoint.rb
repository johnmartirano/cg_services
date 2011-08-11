require 'typhoeus'
require 'active_record'
require 'cg_service_client'

module CgRoleClient
  class RestEndpoint < CgServiceClient::RestEndpoint

    SECONDS_IN_A_DAY = 86400
    SECONDS_IN_A_YEAR = SECONDS_IN_A_DAY * 365

    def initialize(uri, version)
      super
    end

    def find_all_role_types
      request_url = uri_with_version + "roles/types/"
      request = Typhoeus::Request.new(request_url,
                                      :method => :get,
                                      :headers => {"Accept" => "application/json"},
                                      :timeout => RestEndpoint::REQEUST_TIMEOUT,
                                      :cache_timeout => SECONDS_IN_A_DAY)

      role_types = []
      run_typhoeus_request(request) do |response|
        decoded_role_types = ActiveSupport::JSON.decode(response.body)
        decoded_role_types.each do |role_type_attributes|
          role_types << CgRoleClient::RoleType.new(role_type_attributes)
        end
      end
      role_types
    end

    def find_role_type_by_id(id)
      request_url = uri_with_version + "roles/types/" + id.to_s
      request = Typhoeus::Request.new(request_url,
                                      :method => :get,
                                      :headers => {"Accept" => "application/json"},
                                      :timeout => RestEndpoint::REQEUST_TIMEOUT,
                                      :cache_timeout => SECONDS_IN_A_DAY)
      run_typhoeus_request(request) do |response|
        CgRoleClient::RoleType.new.from_json(response.body)
      end
    end

    def find_role_type_activities_by_role_type_id(id)
      request_url = uri_with_version + "roles/types/" + id.to_s + "/activities/"
      request = Typhoeus::Request.new(request_url,
                                      :method => :get,
                                      :headers => {"Accept" => "application/json"},
                                      :timeout => RestEndpoint::REQEUST_TIMEOUT,
                                      :cache_timeout => SECONDS_IN_A_DAY)
      activities = []
      run_typhoeus_request(request) do |response|
        decoded_activities = ActiveSupport::JSON.decode(response.body)
        decoded_activities.each do |activity_attributes|
          activities << CgRoleClient::Activity.new(activity_attributes)
        end
      end
      activities
    end

    def find_singleton_group_by_actor_id(id)
      request_url = uri_with_version + "actors/" + id.to_s + "/groups/singleton/"
      request = Typhoeus::Request.new(request_url,
                                      :method => :get,
                                      :headers => {"Accept" => "application/json"},
                                      :timeout => RestEndpoint::REQEUST_TIMEOUT,
                                      :cache_timeout => SECONDS_IN_A_YEAR)
      run_typhoeus_request(request) do |response|
        CgRoleClient::Group.new.from_json(response.body)
      end
    end

    def create_role(role)
      request_url = uri_with_version + "groups/" + role.group_id.to_s + "/roles/"
      request = Typhoeus::Request.new(request_url,
                                      :body => role.to_json,
                                      :method => :post,
                                      :headers => {"Accept" => "application/json", "Content-Type" => "application/json; charset=utf-8"},
                                      :timeout => RestEndpoint::REQEUST_TIMEOUT)
      run_typhoeus_request(request) do |response|
        CgRoleClient::Role.new.from_json(response.body)
      end
    end

    def find_roles(group_id, target_type, target_id)
      request_url = uri_with_version + "groups/" + group_id.to_s + "/roles/"
      request = Typhoeus::Request.new(request_url,
                                      :method => :get,
                                      :headers => {"Accept" => "application/json"},
                                      :params  => {:target_type => target_type, :target_id => target_id},
                                      :timeout => RestEndpoint::REQEUST_TIMEOUT)

      roles = []
      run_typhoeus_request(request) do |response|
        decoded_roles = ActiveSupport::JSON.decode(response.body)
        decoded_roles.each do |role_attributes|
          roles << CgRoleClient::Role.new(role_attributes)
        end
      end
      roles
    end

    def create_actor(actor)
      request_url = uri_with_version + "actors/"
      request = Typhoeus::Request.new(request_url,
                                      :body => actor.to_json,
                                      :method => :post,
                                      :headers => {"Accept" => "application/json", "Content-Type" => "application/json; charset=utf-8"},
                                      :timeout => RestEndpoint::REQEUST_TIMEOUT)
      run_typhoeus_request(request) do |response|
        CgRoleClient::Actor.new.from_json(response.body)
      end
    end

    def find_role_type_by_role_name_and_target_type(role_name, target_type)
      request_url = uri_with_version + "roles/types/" + role_name.to_s.capitalize
      request = Typhoeus::Request.new(request_url,
                                      :method => :get,
                                      :headers => {"Accept" => "application/json"},
                                      :params  => {:target_type => target_type},
                                      :timeout => RestEndpoint::REQEUST_TIMEOUT)
      run_typhoeus_request(request) do |response|
        CgRoleClient::RoleType.new.from_json(response.body)
      end
    end

    def find_activity_by_code(code)
      request_url = uri_with_version + "activities/" + code.to_s
      request = Typhoeus::Request.new(request_url,
                                      :method => :get,
                                      :headers => {"Accept" => "application/json"},
                                      :timeout => RestEndpoint::REQEUST_TIMEOUT)
      run_typhoeus_request(request) do |response|
        CgRoleClient::Activity.new.from_json(response.body)
      end
    end

  end
end
