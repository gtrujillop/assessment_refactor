module Player
  class ZypeRenderer < Player::Renderer
    def initialize(data_source, options={})
      super(data_source, options)
      @referer_https = detect_referer_https
    end

    def render
      set_zype_player_components
      player.to_json
    end

   def default_thumbnail_url
      if t = @data_source.thumbnails.max_by(&:height)
        t.url
      end
    end
    private :default_thumbnail_url

    def subtitles
      @data_source.video.subtitles.active.order(language: :asc).collect do |s|
        { file: s.file.url,
          label: s.language_name,
          kind: 'captions' }
      end
    end
    private :subtitles

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
    private :logo_plugin

     def age_gate_plugin
      {
        content_url("/jwplayer/agegate.js") => {
          cookielife: 60,
          minage: @data_source.video.site.age_gate_min_age
        }
      }
    end   
    private :age_gate_plugin

    def ga_plugin
      {
        ga: {
          idstring: "title",
          trackingobject: @data_source.video.site.ga_object,
          label: "title"
        }
      }
    end
    private :ga_plugin

    def set_zype_player_components
      player.merge!({
        image: default_thumbnail_url,
        tracks: subtitles
      })
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
    end
    private :set_zype_player_components
  end
end