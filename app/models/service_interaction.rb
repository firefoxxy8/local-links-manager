class ServiceInteraction < ApplicationRecord
  validates :service_id, :interaction_id, presence: true
  validates :service_id, uniqueness: { scope: :interaction_id }

  belongs_to :service, touch: true
  belongs_to :interaction
  has_many :links

  delegate :lgsl_code, to: :service
  delegate :lgil_code, to: :interaction

  def self.find_by_lgsl_and_lgil(lgsl_code, lgil_code)
    includes(:service, :interaction)
      .references(:service, :interaction)
      .find_by(services: { lgsl_code: lgsl_code }, interactions: { lgil_code: lgil_code })
  end
end
