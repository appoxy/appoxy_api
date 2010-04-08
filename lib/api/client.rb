module Appoxy
    module Api

        # Subclass must define:
        #  host: endpoint url for service
        class Client

            attr_accessor :host, :access_key, :secret_key

            def initialize(host, access_key, secret_key, options={})
                @host = host
                @access_key = access_key
                @secret_key = secret_key
            end

            def get(method, params={}, options={})
                parse_response ClientHelper.run_http(host, access_key, secret_key, :get, method, nil, params)
            end

            def post(method, params={}, options={})
               parse_response ClientHelper.run_http(host, access_key, secret_key, :post, method, nil, params)
            end

            def put(method, body, options={})
                parse_response ClientHelper.run_http(host, access_key, secret_key, :put, method, body, nil)
            end

            def parse_response(response)
                begin
                    return ActiveSupport::JSON.decode(response)
                rescue => ex
                    puts 'response that caused error = ' + response.to_s
                    raise ex
                end
            end


        end

    end
end
