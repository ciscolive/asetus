class Asetus
  # 将 ruby 数据结构转换为 json
  def to_json(config)
    Adapter::JSON.to config._asetus_to_hash
  end

  # 将 json 转换为 ruby 数据结构
  def from_json(json)
    Adapter::JSON.from json
  end

  class Adapter
    class JSON
      class << self
        def to(hash)
          require 'json'
          ::JSON.pretty_generate hash
        end

        def from(json)
          require 'json'
          ::JSON.load json
        end
      end
    end
  end
end
