FactoryBot.define do
  factory :link do
    association :local_authority
    association :service_interaction
    sequence(:url) { |n| "http://www.example.com/#{n}" }
    status nil
    link_last_checked nil
    analytics 0
  end

  factory :missing_link, parent: :link do
    url nil
    status "missing"
  end

  factory :broken_link, parent: :link do
    url nil
    status "broken"
  end

  factory :link_for_disabled_service, parent: :link do
    after(:create) do |link|
      link.service.update_attribute(:enabled, false)
    end
  end
end
