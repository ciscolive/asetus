require_relative 'asetus/config_struct'
require_relative 'asetus/adapter/yaml'
require_relative 'asetus/adapter/json'
require_relative 'asetus/adapter/toml'
require 'fileutils'

class AsetusError < StandardError; end

class NoName < AsetusError; end

class UnknownOption < AsetusError; end

# @example common use case
#   CFGS = Asetus.new :name=>'my_sweet_program' :load=>false   # do not load config from filesystem
#   CFGS.default.ssh.port      = 22
#   CFGS.default.ssh.hosts     = %w(host1.example.com host2.example.com)
#   CFGS.default.auth.user     = lana
#   CFGS.default.auth.password = dangerzone
#   CFGS.load  # load system config and user config from filesystem and merge with defaults to #cfg
#   raise StandardError, 'edit ~/.config/my_sweet_program/config' if CFGS.create  # create user config from default config if no system or user config exists
#   # use the damn thing
#   CFG = CFGS.cfg
#   user      = CFG.auth.user
#   password  = CFG.auth.password
#   ssh_port  = CFG.ssh.port
#   ssh_hosts = CFG.ssh.hosts
class Asetus
  CONFIG_FILE = 'config'
  # 对象属性
  attr_reader :cfg, :default, :file
  # 支持设置系统和用户配置
  attr_accessor :system, :user

  # 类方法
  class << self
    def cfg(*args)
      new(*args).cfg
    end
  end

  # 从项目全局配置、用户配置和缺省配置加载 -- 合并配置
  # 用户配置>项目配置
  # When this is called, by default :system and :user are loaded from
  # filesystem and merged with default, so that user overrides system which
  # overrides default
  #
  # @param [Symbol] level which configuration level to load, by default :all
  # @return [void]
  def load(level = :all)
    # 加载缺省配置并合并
    @cfg = merge(@cfg, @default) if %i[default all].include?(level)
    # 加载系统配置并合并
    if %i[system all].include?(level)
      @system = load_cfg(@sysdir)
      @cfg    = merge(@cfg, @system)
    end
    # 如果没有定义用户配置则跳过后续逻辑
    return unless %i[user all].include?(level)

    # 加载用户配置并合并
    @user = load_cfg(@usrdir)
    @cfg  = merge(@cfg, @user)
  end

  # 自动保存配置文件 -- 缺省保存到用户家目录
  # @param [Symbol] level which configuration level to save, by default :user
  # @return [void]
  def save(level = :user)
    if level == :user
      save_cfg(@usrdir, @user)
    elsif level == :system
      save_cfg(@sysdir, @system)
    end
  end

  # 自动装配 -- 设定缺省配置并抛出异常
  # @example create user config from default config and raise error, if no config was found
  #   raise StandardError, 'edit ~/.config/name/config' if asetus.create
  # @param [Hash] opts options for Asetus
  # @option opts [Symbol]  :source       source to use for settings to save, by default :default
  # @option opts [Symbol]  :destination  destination to use for settings to save, by default :user
  # @option opts [boolean] :load         load config once saved, by default false
  # @return [boolean] true if config didn't exist and was created, false if config already exists
  def create(opts = {})
    # 设定源目文件路径
    src = opts.delete(:source) || :default
    dst = opts.delete(:destination) || :user

    # 缺省状态为没有配置文件
    # 如果项目和用户配置文件为空，则自动创建(保存)缺省配置
    # 同时自动合并项目、用户配置参数 -- 用户配置>项目配置
    no_config = false
    no_config = true if @system.empty? && @user.empty?
    if no_config
      # 动态加载缺省配置并写入到用户或项目配置路径
      src = instance_variable_get "@#{src}"
      instance_variable_set("@#{dst}", src.dup)
      # 保存缺省配置文件
      save(dst)
      # 合并项目和用户配置
      load if opts.delete(:load)
    end
    no_config
  end

  private

  # 实例化函数
  # @param [Hash] opts options for Asetus.new
  # @option opts [String]  :name     name to use for asetus (/etc/name/, ~/.config/name/) - autodetected if not defined
  # @option opts [String]  :adapter  adapter to use 'yaml', 'json' or 'toml' for now
  # @option opts [String]  :usrdir   directory for storing user config ~/.config/name/ by default
  # @option opts [String]  :sysdir   directory for storing system config /etc/name/ by default
  # @option opts [String]  :cfgfile  configuration filename, by default CONFIG_FILE
  # @option opts [Hash]    :default  default settings to use
  # @option opts [boolean] :load     automatically load+merge system+user config with defaults in #cfg
  # @option opts [boolean] :key_to_s convert keys to string by calling #to_s for keys
  def initialize(opts = {})
    @name    = (opts.delete(:name) || metaname)
    @adapter = (opts.delete(:adapter) || 'yaml')
    @usrdir  = (opts.delete(:usrdir) || File.join(Dir.home, '.config', @name))
    @sysdir  = (opts.delete(:sysdir) || File.join('/etc', @name))
    @cfgfile = (opts.delete(:cfgfile) || CONFIG_FILE)
    # 用户设定的缺省配置
    @default = ConfigStruct.new opts.delete(:default)
    # 项目全局配置
    @system = ConfigStruct.new
    # 用户设定配置
    @user = ConfigStruct.new
    @cfg  = ConfigStruct.new
    # 是否指定 load 状态
    @load     = true
    @load     = opts.delete(:load) if opts.has_key?(:load)
    @key_to_s = opts.delete(:key_to_s)
    raise UnknownOption, "option '#{opts}' not recognized" unless opts.empty?

    # 加载项目、用户配置文件并合并参数
    load(:all) if @load
  end

  # 加载配置文件
  def load_cfg(dir)
    @file = File.join(dir, @cfgfile)
    file  = File.read(@file)
    ConfigStruct.new(from(@adapter, file), key_to_s: @key_to_s)
  rescue Errno::ENOENT
    ConfigStruct.new
  end

  # 保存配置文本
  def save_cfg(dir, config)
    config = to(@adapter, config)
    file   = File.join(dir, @cfgfile)
    FileUtils.mkdir_p(dir)
    File.write(file, config)
  end

  # 合并配置
  def merge(*configs)
    hash = {}
    configs.each do |config|
      hash = hash._asetus_deep_merge(config._asetus_to_hash)
    end
    ConfigStruct.new(hash)
  end

  # 从 adapter 转换为 ruby 数据结构
  def from(adapter, config)
    name = 'from_' + adapter
    send(name, config)
  end

  # 将 ruby 数据结构转换为 adapter
  def to(adapter, config)
    name = 'to_' + adapter
    send(name, config)
  end

  # 该代码的目的是动态获取调用方法所在文件的名称
  # 它假设文件名足以进行进一步处理，如果无法确定名称，则会抛出异常。
  def metaname
    path = caller_locations[-1].path
    File.basename(path, File.extname(path))
  rescue StandardError
    raise NoName, "can't figure out name, specify explicitly"
  end
end

class Hash
  # 该方法用于合并哈希对象，如果遇到嵌套的哈希对象，将递归进行深度合并。
  # 这种深度合并保留了嵌套哈希对象的结构，并将相同键的值合并在一起。
  # 如果某个键在原始哈希对象和新的哈希对象中都存在，则使用新的哈希对象中的值。
  def _asetus_deep_merge(new_hash)
    merger = proc do |_key, old_val, new_val|
      old_val.is_a?(Hash) && new_val.is_a?(Hash) ? old_val.merge(new_val, &merger) : new_val
    end
    merge(new_hash, &merger)
  end
end
