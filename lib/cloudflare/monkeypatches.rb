#https://github.com/b4k3r/cloudflare/blob/master/lib/cloudflare/connection.rb
#TODO this is fixed on master but not in the latest version of the gem, allowing service_mode to be set on creates
module CloudFlare
  class Connection
    def rec_new(zone, type, name, content, ttl, prio = nil, service = nil, srvname = nil, protocol = nil, weight = nil, port = nil, target = nil, service_mode = '1')
      send_req({
        a: :rec_new,
        z: zone,
        type: type,
        name: name,
        content: content,
        ttl: ttl,
        prio: prio,
        service: service,
        srvname: srvname,
        protocol: protocol,
        weight: weight,
        port: port,
        target: target,
        service_mode: service_mode
      })
    end
  end
end
