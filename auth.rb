require "openssl"

SHA_KEY = "DFkkjhjkfghdrtuJhjfgkhj7676tYEtyut67587buig67O0jObuy7i6"

def sha256(value)
  nil if value.nil? || value.empty?

  OpenSSL::HMAC.hexdigest("sha256", SHA_KEY, value)
end

USERS = [
  { id: 1, username: "allo", password: sha256("pwd") }
]
  
# Returns corresponding user if username and password are correct
def authenticate(username, password)
  USERS.select do |user|
    user.slice(:username, :password) == { username: username, password: sha256(password) }
  end.first&.slice(:id, :username)
end
