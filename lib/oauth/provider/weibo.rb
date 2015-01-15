module Oauth
  class Weibo < Provider

    def follow(uid = nil)
      uid = Configure['weibo']['official'] if uid.nil?
      api_access('friendships/create', {'uid'=> uid}, 'post')
    end

    def publish(content)
      api_access('statuses/update', {'status'=>content}, 'post')
    end

    def fetch_info
      api_access('users/show',{'uid' => uid})
    end

    def api_access(api, http_params, http_method = 'get')
      return nil if expired? # expired
      url = 'https://api.weibo.com/2/' + api + '.json'
      http_params.merge!({"access_token" => access_token})
      Oauth::Weibo.request(url, http_params, http_method, 'json')
    end

    def refresh
      info = Oauth::Weibo.postJSON('https://api.weibo.com/oauth2/get_token_info', {access_token: access_token})
      if info
        self.created_at = info["create_at"]
        user.save!
      end
    end

    class << self
      def self.authenticate?(access_token, uid)
        result = postJSON('https://api.weibo.com/oauth2/get_token_info', {access_token: access_token})
        if result.try(:[], 'uid').to_i == uid.to_i
          uid.to_i > 0
        else
          false
        end
      end

      def authorize_url
        get_params = {
          'client_id' => Configure['weibo']['appid'],
          'redirect_uri' => Configure['weibo']['callback'],
          'response_type' => 'code',
          'display' => 'default' # for different divice, default|mobile|wap|client|apponweibo
        }
        "https://api.weibo.com/oauth2/authorize?#{URI.encode_www_form(get_params)}";
      end

      def detail_of_code(code)
        url = 'https://api.weibo.com/oauth2/access_token'
        post_params = {
          'client_id' => Configure['weibo']['appid'],
          'client_secret' => Configure['weibo']['secret'],
          'grant_type' => 'authorization_code',
          'code' => code,
          'redirect_uri' => Configure['weibo']['callback']
        }
        response = postJSON(url,post_params)
        if response
          response["created_at"] = Time.now
          response.delete('remind_in')
        end
        response
      end
    end
  end

  class WeiboMobile < Weibo; end
end