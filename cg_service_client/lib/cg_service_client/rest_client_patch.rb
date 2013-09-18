# RestClient is throwing exception for http error codes like 404 by default.
# CG Service Client will handle these kind of exceptions so this patch is required to stub the 
# RestClient exception. The problem occured when cg_role_client is made as JRuby compliant.
module RestClient
  module AbstractResponse
    def return! request = nil, result = nil, & block
      return self
    end
  end
end
