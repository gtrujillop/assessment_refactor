module Player
  class Renderer
     include Player::Manifest

    def initialize(data_source, options={})
      @data_source = data_source
      @options = options
      @referer_https = detect_referer_https
      @player_type = nil
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

    # Set player k => v based on 
    # player type
    def set_player_components(player)
       if @data_source.is_a?(Player::Zype)
        player.playlist[0].merge!({
          image: default_thumbnail_url,
          tracks: subtitles
        })
        player.merge!({ 
          aspectratio: "16:9",
          abouttext: @data_source.site.title,
          aboutlink: @data_source.site.player_logo_link
        })
      end

      if @data_source.is_a?(Player::ZypeAudio)
        player.merge!({ 
          height: '30px'
        })
      end

      if @data_source.is_a?(Player::ZypeLiveAudio)
        player.merge!({ 
          height: 30
        })
      end
    end
    private :set_player_components

    def render
      # build out base player with media information,
      # core settings including width, height, aspect ratio
      # auto start, skin
      player = {
        playlist: [{
          sources: [{file: manifest_url}],
          title: @data_source.video.title,
          mediaid: @data_source.video.id.to_s,
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

      set_player_components(player)

      # if player logo is present merge in the plugin
      if @data_source.site.player_logo.present?
        player.merge!(logo_plugin)
      end

      # if age gate is required merge in the plugin
      if @data_source.video.age_gate_required?
        player[:plugins].merge!(age_gate_plugin)
        # disable autostart when age gate enabled
        player[:autostart] = false
      end
      # if google analytics is required merge in the plugin
      if @data_source.site.ga_enabled?
        player.merge!(ga_plugin)
      end

      if @data_source.site.player_sharing_enabled?
        player.merge!(sharing: {})
      end

      if ad_tag = @options[:ad_tag]
        ad_tag.web_render(player,@data_source,@options)
      end

      player.to_json
    end

    def content_url(path)
      options = {
        host: APP_CONFIG[:content_host],
        port: (referer_https? ? APP_CONFIG[:https_port] : APP_CONFIG[:http_port]),
        path: path
      }

      (referer_https? ? URI::HTTPS : URI::HTTP).build(options).to_s
    end

    def logo_plugin
      {
        logo: {
          file: @data_source.site.player_logo.url(:thumb),
          link: @data_source.site.player_logo_link,
          margin: @data_source.site.player_logo_margin,
          position: @data_source.site.player_logo_position,
          hide: @data_source.site.player_logo_hide
        }
      }
    end

    def subtitles
      @data_source.video.subtitles.active.order(language: :asc).collect do |s|
        { file: s.file.url,
          label: s.language_name,
          kind: 'captions' }
      end
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

    def age_gate_plugin
      {
        content_url("/jwplayer/agegate.js") => {
          cookielife: 60,
          minage: @data_source.video.site.age_gate_min_age
        }
      }
    end

    def default_thumbnail_url
      if t = @data_source.thumbnails.max_by(&:height)
        t.url
      end
    end
  end
end