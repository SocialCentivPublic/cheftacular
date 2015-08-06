#https://github.com/reset/ridley/blob/master/lib/ridley/chef_objects/data_bag_item_obect.rb
#This monkeypatch fixes decrypt being unable to return unencrypted data for encrypted bags with nested hashes in hashes
module Ridley
  class DataBagItemObject < ChefObject
    def decrypt
      decrypted_hash = Hash[_attributes_.map { |key, value| [key, key == "id" ? value : decrypt_value(value)] }]

      Hashie::Mash.new(decrypted_hash) #old:mass_assign(decrypted_hash)
    end
  end
end

module Ridley
  class NodeObject < Ridley::ChefObject
    def public_ipv4
      address = self.cloud? ? self.automatic[:cloud][:public_ipv4] || self.automatic[:ipaddress] : self.automatic[:ipaddress]
      
      address.is_a?(Hash) ? address['ip_address'] : address
    end

    alias_method :public_ipaddress, :public_ipv4
  end
end
