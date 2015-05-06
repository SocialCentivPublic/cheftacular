
class Cheftacular
  class Encryptor
    ALGORITHM = 'aes-256-cbc'

    def initialize data_bag_secret
      @data_bag_secret = data_bag_secret
    end

    def return_encrypted_hash hash
      hash.each_pair do |key, value|
        hash[key] = encrypt_data_for_databag(value) unless (key =~ /id/) == 0
      end

      hash
    end

    #https://github.com/opscode/chef/blob/master/lib/chef/encrypted_data_bag_item/encryptor.rb
    def encrypt_data_for_databag string
      encryptor = openssl_encryptor

      {
        "encrypted_data" => encrypt_string(string, encryptor),
        "iv" =>  Base64.encode64(@iv),
        "version" => 1,
        "cipher" => ALGORITHM
      }
    end

    def encrypt_string string, encryptor
      enc_data = encryptor.update(FFI_Yajl::Encoder.encode(json_wrapper: string))
      enc_data << encryptor.final

      Base64.encode64(enc_data)
    end

    def openssl_encryptor
      openssl_encryptor = begin
        encryptor = OpenSSL::Cipher::Cipher.new(ALGORITHM)
        encryptor.encrypt
        @iv = encryptor.random_iv
        encryptor.iv = @iv
        encryptor.key = Digest::SHA256.digest(@data_bag_secret)
        encryptor
      end
    end
  end
end
