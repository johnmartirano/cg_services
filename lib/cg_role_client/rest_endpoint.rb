require 'typhoeus'
require 'active_record'
require 'cg_service_client'

module CgRoleClient
  class RestEndpoint < CgServiceClient::RestEndpoint

    SECONDS_IN_A_DAY = 86400
    SECONDS_IN_A_YEAR = SECONDS_IN_A_DAY * 365
    REQUEST_TIMEOUT = CgServiceClient::RestEndpoint::REQUEST_TIMEOUT
    
    def initialize(uri, version)
      super
    end

    def find_all_role_types
      request_url = uri_with_version + "roles/types/"
      request = Typhoeus::Request.new(request_url,
                                      :method => :get,
                                      :headers => {"Accept" => "application/json"},
                                      :timeout => REQUEST_TIMEOUT,
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
                                      :timeout => REQUEST_TIMEOUT,
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
                                      :timeout => REQUEST_TIMEOUT,
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
                                      :timeout => REQUEST_TIMEOUT,
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
                                      :timeout => REQUEST_TIMEOUT)
      run_typhoeus_request(request) do |response|
        CgRoleClient::Role.new.from_json(response.body)
      end
    end

    def find_group_roles_on_target(group_id, target_type, target_id)
      request_url = uri_with_version + "groups/" + group_id.to_s + "/roles/"
      request = Typhoeus::Request.new(request_url,
                                      :method => :get,
                                      :headers => {"Accept" => "application/json"},
                                      :params  => {:target_type => target_type, :target_id => target_id},
                                      :timeout => REQUEST_TIMEOUT)

      roles = []
      begin
        run_typhoeus_request(request) do |response|
          decoded_roles = ActiveSupport::JSON.decode(response.body)
          decoded_roles.each do |role_attributes|
            roles << CgRoleClient::Role.new(role_attributes)
          end
        end
      rescue ::CgServiceClient::Exceptions::ClientError => e
        raise unless e.http_code == 404
      end
      roles
    end

    def find_actor_roles_on_target(actor_id, target_type, target_id)
      request_url = uri_with_version + "actors/" + actor_id.to_s + "/roles/"
      request = Typhoeus::Request.new(request_url,
                                      :method => :get,
                                      :headers => {"Accept" => "application/json"},
                                      :params  => {:target_type => target_type, :target_id => target_id},
                                      :timeout => REQUEST_TIMEOUT)

      roles = []
      begin
        run_typhoeus_request(request) do |response|
          decoded_roles = ActiveSupport::JSON.decode(response.body)
          decoded_roles.each do |role_attributes|
            roles << CgRoleClient::Role.new(role_attributes)
          end
        end
      rescue ::CgServiceClient::Exceptions::ClientError => e
        raise unless e.http_code == 404
      end
      roles
    end

    def create_actor(actor)
      request_url = uri_with_version + "actors/"
      request = Typhoeus::Request.new(request_url,
                                      :body => actor.to_json,
                                      :method => :post,
                                      :headers => {"Accept" => "application/json", "Content-Type" => "application/json; charset=utf-8"},
                                      :timeout => REQUEST_TIMEOUT)
      run_typhoeus_request(request) do |response|
        CgRoleClient::Actor.new.from_json(response.body)
      end
    end

    def find_actor_by_actor_type_and_actor_id(actor_type, actor_id)
      request_url = uri_with_version + "actors/"
      request = Typhoeus::Request.new(request_url,
                                      :method => :get,
                                      :headers => {"Accept" => "application/json"},
                                      :params  => {:actor_type => actor_type, :actor_id => actor_id},
                                      :timeout => REQUEST_TIMEOUT,
                                      :cache_timeout => SECONDS_IN_A_YEAR)
      run_typhoeus_request(request) do |response|
        CgRoleClient::Actor.new.from_json(response.body)
      end
    end

    def find_role_type_by_role_name_and_target_type(role_name, target_type)
      request_url = uri_with_version + "roles/types/" + role_name.to_s.camelcase
      request = Typhoeus::Request.new(request_url,
                                      :method => :get,
                                      :headers => {"Accept" => "application/json"},
                                      :params  => {:target_type => target_type},
                                      :timeout => REQUEST_TIMEOUT)
      run_typhoeus_request(request) do |response|
        CgRoleClient::RoleType.new.from_json(response.body)
      end
    end

    def find_activity_by_code(code)
      request_url = uri_with_version + "activities/" + code.to_s
      request = Typhoeus::Request.new(request_url,
                                      :method => :get,
                                      :headers => {"Accept" => "application/json"},
                                      :timeout => REQUEST_TIMEOUT,
                                      :cache_timeout => SECONDS_IN_A_DAY)
      run_typhoeus_request(request) do |response|
        CgRoleClient::Activity.new.from_json(response.body)
      end
    end

    def find_group_by_code(code)
      request_url = uri_with_version + "groups/" + code.to_s
      request = Typhoeus::Request.new(request_url,
                                      :method => :get,
                                      :headers => {"Accept" => "application/json"},
                                      :timeout => REQUEST_TIMEOUT)
      begin
        run_typhoeus_request(request) do |response|
          CgRoleClient::Group.new.from_json(response.body)
        end
      rescue ::CgServiceClient::Exceptions::ClientError => e
        raise unless e.http_code == 404
        nil
      end
    end

    def create_group(group)
      request_url = uri_with_version + "groups/"
      request = Typhoeus::Request.new(request_url,
                                      :body => group.to_json,
                                      :method => :post,
                                      :headers => {"Accept" => "application/json", "Content-Type" => "application/json; charset=utf-8"},
                                      :timeout => REQUEST_TIMEOUT)
      run_typhoeus_request(request) do |response|
        CgRoleClient::Group.new.from_json(response.body)
      end
    end

    def  find_with_roles_on_target(target_id, target_type)
      request_url = uri_with_version + "actors/with_roles_on_target/"
      request = Typhoeus::Request.new(request_url,
                                      :params  => {:target_type => target_type,
                                                   :target_id => target_id},
                                      :method => :get,
                                      :headers => {"Accept" => "application/json"},
                                      :timeout => REQUEST_TIMEOUT)
      actors = []
      begin
        run_typhoeus_request(request) do |response|
          decoded_actors = ActiveSupport::JSON.decode(response.body)
          decoded_actors.each do |actor_attributes|
            actors << CgRoleClient::Actor.new(actor_attributes)
          end
        end
      rescue ::CgServiceClient::Exceptions::ClientError => e
        raise unless e.http_code == 404
      end

      actors
    end

    def find_targets_with_activities_for_this_actor(actor, activity_ids, target_type_strings)
      request_url = uri_with_version + "actors/" + actor.id.to_s + "/targets_with_activities"
      request = Typhoeus::Request.new(request_url,
                                      :method => :get,
                                      :headers => {"Accept" => "application/json"},
                                      :params => { :activities => activity_ids.to_json,#get around passing array by passing a string representation of it
                                      # role_service drops a parameter instead of detecting the array if it receives ?activities=foo&activities=bar
                                      # it requires instead the nonstandard ?activities[]=foo&activities[]=bar
                                      # :symbols cannot contain "[]", so use strings
                                      # see http://groups.google.com/group/typhoeus/browse_thread/thread/94a5ebf3c226acde?pli=1
                                      # and Typhoeus::Utils param string methods
                                      :target_types => target_type_strings.to_json,
                                      :actor_type => actor.actor_type },
                                      :timeout => REQUEST_TIMEOUT,
                                      :cache_timeout => 5 * 60) # set the cache timeout to 5 minutes, since search is what uses this and its cache times out at 5 minutes
      #cache_timeout?
      targets = []
      begin
        run_typhoeus_request(request) do |response|
          decoded_targets = ActiveSupport::JSON.decode(response.body)
          targets = decoded_targets.map { |target_attributes| CgRoleClient::Target.new(target_attributes) }
        end
      rescue ::CgServiceClient::Exceptions::ClientError => e
        raise unless e.http_code == 404
      end
    end


    def find_group_actors_by_group_id(id)
      request_url = uri_with_version + "groups/" + id.to_s + "/actors"
      request = Typhoeus::Request.new(request_url,
                                      :method => :get,
                                      :headers => {"Accept" => "application/json"},
                                      :timeout => REQUEST_TIMEOUT)
      actors = []
      run_typhoeus_request(request) do |response|
        decoded_actors = ActiveSupport::JSON.decode(response.body)
        decoded_actors.each do |actor_attributes|
          actors << CgRoleClient::Actor.new(actor_attributes)
        end
      end
      actors
    end

    def add_actor_to_group(group_id, actor)
      request_url = uri_with_version + "groups/" + group_id.to_s + "/actors/"
      request = Typhoeus::Request.new(request_url,
                                      :body => actor.to_json,
                                      :method => :post,
                                      :headers => {"Accept" => "application/json", "Content-Type" => "application/json; charset=utf-8"},
                                      :timeout => REQUEST_TIMEOUT)
      run_typhoeus_request(request) do |response|
        response.body
      end
    end

    def remove_actor_from_group(group_id, actor)
      request_url = uri_with_version + "groups/" + group_id.to_s + "/actors/"
      request = Typhoeus::Request.new(request_url,
                                      :body => actor.to_json,
                                      :method => :delete,
                                      :headers => {"Accept" => "application/json", "Content-Type" => "application/json; charset=utf-8"},
                                      :timeout => REQUEST_TIMEOUT)
      run_typhoeus_request(request) do |response|
        response.body
      end
    end

    def find_target_by_target_type_and_actor_type_and_actor_id(target_type,actor_type,actor_id)
      request_url = uri_with_version + "targets/"
      request = Typhoeus::Request.new(request_url,
                                      :method => :get,
                                      :headers => {"Accept" => "application/json"},
                                      :params  => {:target_type => target_type,
                                                   :actor_type => actor_type, :actor_id => actor_id},
                                      :timeout => REQUEST_TIMEOUT)
      targets = []
      begin
        run_typhoeus_request(request) do |response|
          decoded_target_ids = ActiveSupport::JSON.decode(response.body)
          decoded_target_ids.each do |target_id|
            targets << CgRoleClient::Target.new({:target_id => target_id, :target_type => target_type})
          end
        end
      rescue ::CgServiceClient::Exceptions::ClientError => e
        raise unless e.http_code == 404
      end
      targets
    end

    def remove_role(role_id)
      request_url = uri_with_version + "roles/" + role_id.to_s
      request = Typhoeus::Request.new(request_url,
                                      :method => :delete,
                                      :headers => {"Accept" => "application/json", "Content-Type" => "application/json; charset=utf-8"},
                                      :timeout => REQUEST_TIMEOUT)
      run_typhoeus_request(request) do |response|
        response.body
      end
    end

    def find_actors_by_target_and_target_type_and_activities(target_id, target_type, activity_ids)
      request_url = uri_with_version + "targets/" + target_id + "/actors_with_activities"
      request = Typhoeus::Request.new(request_url,
                                     :method => :get,
                                     :headers => {"Accept" => "application/json"},
                                     :params => {:activities => activity_ids.to_json,
                                                 :target_type => target_type},
                                     :timeout => REQUEST_TIMEOUT)
      actors = []
      begin
        run_typhoeus_request(request) do |response|
          decoded_actors = ActiveSupport::JSON.decode(response.body)
          decoded_actors.each do |actor_attributes|
            actors << CgRoleClient::Actor.new(actor_attributes)
          end
        end
      rescue ::CgServiceClient::Exceptions::ClientError => e
        raise unless e.http_code == 404
      end
      actors
    end
  end
end
