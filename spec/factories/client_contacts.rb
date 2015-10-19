FactoryGirl.define do
  sequence :email do |n|
    "person#{n}@example.com"
  end

  sequence :first_name do |n|
    "fn#{n}"
  end

  sequence :last_name do |n|
    "ln#{n}"
  end

  factory :client_contact do
    client_email 'client@test.com'
    email
    first_name
    last_name
  end

end