module OmniAuth
  module Strategies
    class OpenIdLk
      include OmniAuth::Strategy

      option :name, :open_id_***REMOVED***

      option :server, nil
      option :server_param, 'server_url'
      option :identity, nil
      option :mandatory_fields, []

      option :sign_in, "http://#{SERVER_CONFIG['hostname']}/users/sign_in"

      uid { request.params['openid.assoc_handle'] }

      info do
        options.mandatory_fields.inject({}) do |hash, field|
          hash[field] = request.params['openid.sreg.' + field.to_s]
          hash
        end
      end

      # Создать url запроса на OpenId сервер
      def generate_url
        params = {}

        params['openid.return_to']      = options.identity.to_s
        params['openid.mode']           = 'checkid_setup'
        params['openid.identity']       = options.identity.to_s
        params['openid.trust_root']     = options.identity.to_s
        params['openid.sreg.required']  = options.mandatory_fields.join(',')

        options.server.to_s + '?' + array_to_url(params)
      end

      # Преобразовать хэш параметров в строку запроса (без адреса сервера)
      def array_to_url(params)
        false unless params

        params.map { |key, value| key + '=' + value }.join('&')
      end

      def request_phase
        redirect generate_url
      end

      def callback_phase
        if request.params['openid.mode'] == 'id_res'
          super
        else
          redirect options.sign_in.to_s
        end
      end
    end
  end
end