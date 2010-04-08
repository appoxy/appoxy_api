module Appoxy
    module Api
        module ClientHelper

            # TODO: SWAP OUT ALL THIS CRAP AND USE REST-CLIENT INSTEAD

            # body is a hash
            def self.run_http(host, access_key, secret_key, http_method, command_path, body=nil, parameters={}, extra_headers=nil)
                ts = Appoxy::Api::Signatures.generate_timestamp(Time.now.gmtime)
                # puts 'timestamp = ' + ts
                sig = Appoxy::Api::Signatures.generate_signature(command_path, ts, secret_key)
                # puts "My signature = " + sig
                url = host + command_path
                # puts url

                user_agent = "Appoxy API Ruby Client"
                headers = {'User-Agent' => user_agent}

                if !extra_headers.nil?
                    extra_headers.each_pair do |k, v|
                        headers[k] = v
                    end
                end

                extra_params = {'sigv'=>"0.1", 'sig' => sig, 'timestamp' => ts, 'access_key' => access_key}
                if http_method == :put
                    body.update(extra_params)
                else
                    parameters = {} if parameters.nil?
                    parameters.update(extra_params)
#                puts 'params=' + parameters.inspect

                end


                uri = URI.parse(url)
                #puts 'body=' + body.to_s
                if (http_method == :put)
                    req = Net::HTTP::Put.new(uri.path)
                    body = ActiveSupport::JSON.encode(body)
                    req.body = body unless body.nil?
                elsif (http_method == :post)
                    req = Net::HTTP::Post.new(uri.path)
                    if !parameters.nil?
                        req.set_form_data(parameters)
                    else
                        req.body = body unless body.nil?
                    end
                elsif (http_method == :delete)
                    req = Net::HTTP::Delete.new(uri.path)
                    if !parameters.nil?
                        req.set_form_data(parameters)
                    end
                else
                    req = Net::HTTP::Get.new(uri.path)
                    if !parameters.nil?
                        req.set_form_data(parameters)
                    end
                end
                headers.each_pair do |k, v|
                    req[k] = v
                end
                # req.each_header do |k, v|
                # puts 'header ' + k + '=' + v
                #end
                res = Net::HTTP.start(uri.host, uri.port) do |http|
                    http.request(req)
                end

                ret = ''
                case res
                    when Net::HTTPSuccess
                        # puts 'response body=' + res.body
                        ret = res.body
                    when Net::HTTPClientError
                        raise ClientError.new(res.class.name, ActiveSupport::JSON.decode(res.body))
                    else
                        #res.error
                        puts 'ERROR BODY=' + res.body
                        raise ServiceError.new(res.class.name, res.body)
                end
                return ret

            end

        end

        class ClientError < StandardError

            attr_reader :response_hash

            def initialize(class_name, response_hash)
                puts 'response-hash=' + response_hash.inspect
                super("#{class_name} - #{response_hash["msg"]}")
                @response_hash = response_hash
            end
        end

        class ServiceError < StandardError
            attr_reader :body

            def initialize(class_name, body)
                super("#{class_name}")
                @body = body

            end
        end
    end
end
	