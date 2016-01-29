FactoryGirl.define do

  sequence :name do |n|
    "operatorName#{n}"
  end

  factory :operator do
    email
    name
    salt 'abc'
    encrypted_password { Digest::SHA2.hexdigest('abc' + 'password') }
    ips_whitelist_enabled false

    trait :admin do
      privilege 'admin'
    end

    trait :is_active do
      active true
    end

    factory :operator_admin, traits: [:admin, :is_active]
    factory :operator_actif, traits: [:is_active]
  end
end