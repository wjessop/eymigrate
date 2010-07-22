require 'ghost'
require 'yaml'

class HostList
  include Enumerable
  
  class << self
    def config_file=(path)
      @@config_file = path
    end
    
    def each
      read_entries
      @@entries.each do |host|
        yield host
      end
    end
    
    def set_entry(host, ip = nil)
      if ip
        @@entries[host.strip] = ip.strip
      else
        @@entries.delete(host.strip)
      end
      save_entries
    end
    
    def add(host, ip)
      begin
        Host.add(host, ip)
        set_entry(host,ip)
      rescue => e
        puts "Error adding entry: #{e}"
      end
    end
    
    def update(host, ip)
      Host.delete(host)
      Host.add(host,ip)
      set_entry(host,ip)
    end
    
    def remove(host)
      begin
        Host.delete(host)
        set_entry(host)
      rescue => e
        puts "Error removing entry: #{e}"
      end
    end
    
    def apply
      each do |host, ip|
        if Host.find_by_host(host)
          Host.delete(host)
        end
        Host.add(host, ip)
      end
    end
    
    def unapply
      each do |host, ip|
        Host.delete(host) if Host.find_by_host(host)
      end
    end
    
    def has_entries?
      read_entries
      @@entries.size > 0
    end
  
    private
  
    def read_entries
      if File.exists?(@@config_file)
        @@entries = YAML.load_file(@@config_file)
      else
        @@entries = {}
      end
    end
    
    def save_entries
      File.open(@@config_file, "w") do |f|
        f.write(YAML.dump(@@entries))
      end
    end
  end
end