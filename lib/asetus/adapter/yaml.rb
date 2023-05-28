class Asetus
  # 将 ruby 数据结构转换为 yaml
  def to_yaml(config)
    Adapter::YAML.to config._asetus_to_hash
  end

  # 将 yaml 转换为 ruby 数据结构
  def from_yaml(yaml)
    Adapter::YAML.from yaml
  end

  class Adapter
    class YAML
      class << self
        def to(hash)
          require 'yaml'
          ::YAML.dump hash
        end

        def from(yaml)
          require 'yaml'
          ::YAML.unsafe_load yaml
        end
      end
    end
  end
end
