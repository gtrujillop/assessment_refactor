require 'aes_crypt'

class Player::ZypeAudio < Player::Player
  field :audio_required, type: :boolean, default: true

  def build_player(data_source,options={})
    Player::ZypeAudioRenderer.new(data_source,options).render
  end  
end
