require 'aes_crypt'

class Player::ZypeLiveAudio < Player::ZypeLive
  field :on_air_required, type: :boolean, default: true
  field :audio_required, type: :boolean, default: true

  def build_player(data_source,options={})
    Player::ZypeLiveAudioRenderer.new(data_source,options).render
  end
end
