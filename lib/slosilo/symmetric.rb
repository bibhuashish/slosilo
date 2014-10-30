module Slosilo
  class Symmetric
    VERSION_MAGIC = 'G'
    TAG_LENGTH = 16

    def initialize
      @cipher = OpenSSL::Cipher.new 'aes-256-gcm' # NB: has to be lower case for whatever reason.
    end
    
    def encrypt plaintext, opts = {}
      @cipher.reset
      @cipher.encrypt
      @cipher.key = (opts[:key] or raise("missing :key option"))
      @cipher.iv = iv = random_iv
      @cipher.auth_data = opts[:aad] || "" # Nothing good happens if you set this to nil, or don't set it at all
      ctext = @cipher.update(plaintext) + @cipher.final
      tag = @cipher.auth_tag(TAG_LENGTH)
      "#{VERSION_MAGIC}#{tag}#{iv}#{ctext}"
    end

    def decrypt ciphertext, opts = {}
      version, tag, iv, ctext = unpack ciphertext

      raise "Invalid version magic: expected #{VERSION_MAGIC} but was #{version}" unless version == VERSION_MAGIC

      @cipher.reset
      @cipher.decrypt
      @cipher.key = opts[:key]
      @cipher.iv = iv
      @cipher.auth_tag = tag
      @cipher.auth_data = opts[:aad] || ""
      @cipher.update(ctext) + @cipher.final
    end
    
    def random_iv
      @cipher.random_iv
    end
    
    def random_key
      @cipher.random_key
    end

    private
    # return tag, iv, ctext
    def unpack msg
      msg.unpack "aa#{TAG_LENGTH}a#{@cipher.iv_len}a*"
    end
  end
end
