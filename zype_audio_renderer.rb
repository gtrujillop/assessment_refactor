module Player
  class ZypeAudioRenderer < Player::Renderer
    def initialize(data_source, options={})
      super(data_source, options)
    end

    def audio_outputs
      @data_source.outputs.in(preset_id: @data_source.site.audio_preset_ids)
    end

    def audio_files
      audio_outputs.collect{|o| {file: o.download_url,label: o.bitrate}}
    end
  end
end