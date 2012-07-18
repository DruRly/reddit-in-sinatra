Factorygirl.define do
  factory :user do
    first_name 'John'
    last_name  'Doe'
    age        { 1 + rand(100) }
        
    # Child of :user factory, since it's in the `factory :user` block
    factory :admin do
      admin true
    end
  end
end
