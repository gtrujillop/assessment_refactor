module Player
  class ZypeLiveRenderer < Player::Renderer
    def initialize(data_source, options={})
      super(data_source, options)
    end

    def render
      player.to_json
    end

    def manifest_expiration
      @data_source.expire_at.to_i
    end

    def manifest_url
      options = {
        host: APP_CONFIG[:manifest_host], 
        port: (APP_CONFIG[:manifest_https] ? APP_CONFIG[:https_port] : APP_CONFIG[:http_port]),
        path: "/manifest/live/#{@data_source.video.id}.m3u8",
        query: Rack::Utils.build_query(player_key: @data_source.video.player_key, token: manifest_token)
      }

      (APP_CONFIG[:manifest_https] ? URI::HTTPS : URI::HTTP).build(options).to_s
    end
  end
end