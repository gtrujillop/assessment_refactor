module Player
  class Renderer
     include Player::Manifest

    def initialize(data_source, options={})
      @data_source = data_source
      @options = options
      @referer_https = detect_referer_https
    end

    def detect_referer_https
      begin
        return APP_CONFIG[:player_https] if @options[:iframe]

        uri = URI.parse(@options[:referer])
        uri.scheme == 'https'
      rescue StandardError => e
        Rails.logger.warn("Could not determine scheme from referer: #{@options[:referer]}, defaulting to #{APP_CONFIG[:player_https]}")
        APP_CONFIG[:player_https]
      end
    end

    def referer_https?
      @referer_https == true
    end

    def manifest_params
      super.merge(audio: true)
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

    def player
      @player ||= {
        playlist: [{
          sources: [{file: manifest_url}],
          title: @data_source.video.title,
          mediaid: @data_source.video.id.to_s
        }],
        plugins: {},
        androidhls: true,
        autostart: @options[:autoplay] ? true : false,
        flashplayer: content_url('/jwplayer/6.11/jwplayer.flash.swf'),
        html5player: content_url('/jwplayer/6.11/jwplayer.html5.js'),
        primary: APP_CONFIG[:player_default_mode],
        skin: APP_CONFIG[:player_default_skin],
        width: "100%"
      }
    end
    protected :player

    def content_url(path)
      options = {
        host: APP_CONFIG[:content_host],
        port: (referer_https? ? APP_CONFIG[:https_port] : APP_CONFIG[:http_port]),
        path: path
      }

      (referer_https? ? URI::HTTPS : URI::HTTP).build(options).to_s
    end

     def ga_plugin
      {
        ga: {
          idstring: "title",
          trackingobject: @data_source.video.site.ga_object,
          label: "title"
        }
      }
    end
  end
end