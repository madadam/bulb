class User
  include Persistent

  string :email
  string :password

  index :email

  def self.authenticate(email, password)
    if user = get_by_email(email)
      user.authenticated?(password) ? user : nil
    else
      nil
    end
  end

  def authenticated?(password)
    password == self.password
  end

  def name
    email.gsub(/@.*$/, '')
  end
end
