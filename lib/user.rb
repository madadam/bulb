class User
  include Persistent

  persistent_attr_reader    :email
  persistent_attr_accessor  :password

  def self.authenticate(email, password)
    if user = get_by_email(email)
      user.authenticated?(password) ? user : nil
    else
      nil
    end
  end

  def self.get_by_email(email)
    id = DB.hget email_key, email
    id && new(id)
  end

  def authenticated?(password)
    password == self.password
  end

  def email=(value)
    write_attribute :email, value
    DB.hset self.class.email_key, value, id
  end

  def self.email_key
    "#{key}/by-email"
  end

  def delete
    DB.hdel self.class.email_key, email
    super :email, :password
  end
end
