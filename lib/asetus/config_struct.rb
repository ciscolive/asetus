class Asetus
  class ConfigStruct
    # 将 asetus 转换为哈希对象
    def _asetus_to_hash
      hash = {}
      @cfg.each do |key, value|
        value = value._asetus_to_hash if value.instance_of?(ConfigStruct)
        key = key.to_s if @key_to_s
        hash[key] = value
      end
      hash
    end

    # 是否空配置
    def empty?
      @cfg.empty?
    end

    def each(&block)
      @cfg.each(&block)
    end

    # 配置键
    def keys
      @cfg.keys
    end

    # 判定是否包含某个键
    def has_key?(key)
      @cfg.has_key? key
    end

    private

    # 对象实例化函数
    def initialize(hash = nil, opts = {})
      @key_to_s = opts.delete :key_to_s
      @cfg = hash ? _asetus_from_hash(hash) : {}
    end

    # 元编程 -- 动态方法
    # 该方法的作用是在处理未定义的方法调用时， 根据方法名的不同进行不同的操作。
    # 根据方法名是否以 '?' 或 '=' 结尾，以及是否包含 '[]'，分别执行获取值、设置值或获取嵌套值的操作。
    def method_missing name, *args
      # hash#[] --> 查询某个键值对
      name = name.to_s
      name = args.shift if name[0..1] == '[]' # asetus.cfg['foo']
      arg = args.first

      if name[-1..-1] == '?' # asetus.cfg.foo.bar?
        @cfg[name[0..-2]] if @cfg.has_key? name[0..-2]
      elsif name[-1..-1] == '=' # asetus.cfg.foo.bar = 'quux'
        _asetus_set name[0..-2], arg
      else
        _asetus_get name, arg # asetus.cfg.foo.bar
      end
    end

    # 设置 asetus 键值对
    def _asetus_set(key, value)
      @cfg[key] = value
    end

    # 查询某个键值对
    def _asetus_get(key, _value)
      if @cfg.has_key? key
        @cfg[key]
      else
        @cfg[key] = ConfigStruct.new
      end
    end

    # 从 hash 实例化 ConfigStruct -- 本质上为一个哈希
    def _asetus_from_hash(hash)
      cfg = {}
      hash.each do |key, value|
        value = ConfigStruct.new value, key_to_s: @key_to_s if value.instance_of?(Hash)
        cfg[key] = value
      end
      cfg
    end
  end
end
