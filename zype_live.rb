class Player::ZypeLive < Player::Player
  field :on_air_required, type: :boolean, default: true

  def build_player(data_source,options={})
    Player::ZypeLiveRenderer.new(data_source,options).render   
  end
end
