module Player
  class Player
    include Mongoid::Document
    include Mongoid::Timestamps
    include Mongoid::Paranoia

    field :name, type: String
    field :subscription_required, type: Boolean, default: false
    field :ad_tag_required, type: :boolean, default: false
    field :on_air_required, type: :boolean, default: false
    field :download_required, type: :boolean, default: false
    field :audio_required, type: :boolean, default: false

    field :visible, type: Boolean, default: true

    has_and_belongs_to_many :devices

    belongs_to :site
    belongs_to :provider
    belongs_to :revenue_model

    validates :name, presence: true, uniqueness: true
    validates :revenue_model, presence: true
    validates :provider, presence: true

    scope :visible, -> { where(visible: true) }

    index({:site_id => 1},{background: true})
    index({:provider_id => 1},{background: true})
    index({:revenue_model_id => 1},{background: true})

    before_save :clear_cache

    def self.get_available_players(devices, countries)
      # determines the providers that match *all* countries supplied
      providers = Provider.any_of({:countries.in => ["*"]},{:countries.all => countries})

      # this query limits players to any that match *any* of the above providers
      # this query limits players to any that match *all* of the devices supplied
      Player.visible.includes(:provider).
        in(provider_id: providers.collect(&:id)).
        all_in(device_ids: devices.collect(&:id))
    end

    def self.find_with_relations_cached(id, options={})
      Rails.cache.fetch("player/#{id}/with_relations",options) do
        Player.includes(:provider, :revenue_model).find(id)
      end
    end

    def serializable_hash(options = {})
      # exclude zype specific fields
      options ||= {}
      super(options.deep_merge(
        only: [
          :_id,
          :name
        ]
      ){ |key, old, new| Array.wrap(old) + Array.wrap(new) })
    end

    def clear_cache
      Rails.logger.info("Resetting cache for player: #{name} (ID: #{id})")
      Rails.cache.delete("player/#{id}/with_relations")
    end

    def player_source
      File.read("#{Rails.root}/public/jwplayer/6.11/jwplayer.js")
    end

    def render(data_source,options={})
    <<-EOS
#{player_source}

/** Write container **/
if(!document.getElementById('zype_#{data_source.video.id}')) {
  if(document.getElementById('zype_player')) {
    document.getElementById('zype_player').innerHTML = "<div id='zype_#{data_source.video.id}'></div>";
  } else {
    console.log('could not find zype container');
  }
}

jwplayer.key="#{APP_CONFIG[:jwplayer_key]}";
jwplayer("zype_#{data_source.video.id}").setup(#{build_player(data_source,options)});
EOS
  end
end