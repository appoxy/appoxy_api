module Appoxy

    module Api

        # The api controllers that use this should set:
#        protect_from_forgery :only => [] # can add methods to here, eg: :create, :update, :destroy

#                rescue_from SigError, :with => :send_error
#                rescue_from Api::ApiError, :with => :send_error
        # before_filter :verify_signature(params)

        # Your Controller must define a secret_key_for_signature method which will return the secret key to use to generate signature.

        module ApiController

            def verify_signature

                if request.put?
                    # We'll extract params from body instead here
                    # todo: maybe check for json format first in case this is a file or something?
                    body = request.body.read
                    puts 'body=' + body.inspect
                    params2 = ActiveSupport::JSON.decode(body)
                    puts 'params2=' + params2.inspect
                    params.merge! params2
                end

                operation = "#{controller_name}/#{action_name}"
                puts "XXX " + operation

#            puts 'params in base=' + params.inspect

                access_key = params["access_key"]
                sigv = params["sigv"]
                timestamp = params["timestamp"]
                sig = params["sig"]

                raise Appoxy::Api::ApiError, "No access_key" if access_key.nil?
                raise Appoxy::Api::ApiError, "No sigv" if sigv.nil?
                raise Appoxy::Api::ApiError, "No timestamp" if timestamp.nil?
                raise Appoxy::Api::ApiError, "No sig" if sig.nil?

                sig2 = Appoxy::Api::Signatures.generate_signature(operation, timestamp, secret_key_for_signature(access_key))
                raise Appoxy::Api::ApiError, "Invalid signature!" unless sig == sig2

                puts 'Verified OK'

            end

            def sig_should
                raise "You didn't define a sig_should method in your controller!"
            end


            def send_ok(msg={})
                response_as_string = '' # in case we want to add debugging or something
#                respond_to do |format|
                #                format.json { render :json=>msg }
                response_as_string = render_to_string :json => msg
                render :json => response_as_string
#                end
                true
            end


            def send_error(statuscode_or_error, msg=nil)
                exc = nil
                if statuscode_or_error.is_a? Exception
                    exc = statuscode_or_error
                    statuscode_or_error = 400
                    msg = exc.message
                end
                # deprecate status, should use status_code
                json_msg = {"status_code"=>statuscode_or_error, "msg"=>msg}
                render :json=>json_msg, :status=>statuscode_or_error
                true
            end


        end

        class ApiError < StandardError

            def initialize(msg=nil)
                super(msg)

            end

        end

    end

end
