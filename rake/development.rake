namespace :development do
  desc 'Generate an admin user with password'
  task :create_admin do
    username = ENV['USERNAME'] || 'admin'
    password = ENV['PASSWORD'] || 'password'
    hash = Digest::SHA2.new << password

    user = Optopus::User.create!(
      :display_name => username,
      :password => hash.to_s,
      :username => username
    )
    role = Optopus::Role.where(:name => 'admin').first || Optopus::Role.new(:name => 'admin')
    role.users << user
    role.save!
  end
end
