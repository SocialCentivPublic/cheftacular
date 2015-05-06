
class Cheftacular
  class Decryptor
    ALGORITHM = 'aes-256-cbc'

    def initialize data_bag_secret
      @data_bag_secret = data_bag_secret
    end

    def return_decrypted_hash input_hash, return_hash={}
      input_hash.each_pair do |key, value_hash|
        next if key =~ /id/
        next if value_hash['iv'].nil? || value_hash['iv'].empty?

        return_hash[key] = JSON.parse(decrypt_hash(value_hash)).to_hash["json_wrapper"]
      end

      return_hash['id'] = input_hash['id']

      return_hash
    end

    def openssl_decryptor
      openssl_decryptor = begin
        decryptor = OpenSSL::Cipher::Cipher.new(ALGORITHM)
        decryptor.decrypt
        decryptor.key = Digest::SHA256.digest(@data_bag_secret)
        decryptor.iv = @iv
        decryptor
      end
    end

    def decrypt_hash hash
      @iv = Base64.decode64(hash["iv"])

      decryptor = openssl_decryptor

      decrypted_data = decryptor.update(Base64.decode64(hash["encrypted_data"]))

      decrypted_data << decryptor.final

      decrypted_data
    end
  end
end
