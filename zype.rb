require 'aes_crypt'

class Player::Zype < Player::Player

  field :ad_tag_required, type: :boolean, default: true

  def build_player(data_source,options={})
    Player::ZypeRenderer.new(data_source,options).render
  end
end
