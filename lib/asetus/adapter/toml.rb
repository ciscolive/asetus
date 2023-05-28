class Asetus
  # 将 ruby 数据结构转换为 toml
  def to_toml(config)
    Adapter::TOML.to config._asetus_to_hash
  end

  # 将 toml 转换为 ruby 数据结构
  def from_toml(toml)
    Adapter::TOML.from toml
  end

  class Adapter
    class TOML
      class << self
        def to(hash)
          require 'toml'
          ::TOML::Generator.new(hash).body
        end

        def from(toml)
          require 'toml'
          ::TOML.load toml
        end
      end
    end
  end
end
