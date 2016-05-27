module Player
  class ZypeLiveAudioRenderer < Player::Renderer
    def initialize(data_source, options={})
      super(data_source, options)
    end

    def audio_outputs
      @data_source.outputs.in(preset_id: @data_source.site.audio_preset_ids)
    end

    def audio_files
      audio_outputs.collect{|o| {file: o.download_url,label: o.bitrate}}
    end

    def render
      set_zype_audio_player_components
      player.to_json
    end


    def set_zype_live_audio_player_components
      player.merge!({
        height: '30px'
      })
      # if google analytics is required merge in the plugin
      if @data_source.site.ga_enabled?
        player.merge!(ga_plugin)
      end
    end
    private :set_zype_live_audio_player_components
  end
end