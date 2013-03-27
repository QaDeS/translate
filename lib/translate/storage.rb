class Translate::Storage
  attr_accessor :locale
  
  def initialize(locale)
    self.locale = locale.to_sym
  end
  
  def write_to_file
    Translate::File.new(file_path).write(keys)
  end
  
  def self.file_paths(locale)
    Dir.glob(File.join(root_dir, "config", "locales", "**","#{locale}.yml"))
  end
  
  def self.root_dir
    Rails.root
  end
  
  LocaleFile = Struct.new(:source, :gem, :project, :suffix, :lang, :link, :yaml)
  class LocaleFile
    def derive(language)
      new LocaleFile(source, gem, project, (suffix if suffix != lang), language, link, {language.to_sym => {}})
    end
    def name
      [gem, project, suffix, lang].compact.uniq.join(".")
    end
    def filename
      n = name
      FileMappings[n] || n
    end
  end
  
  def self.sources
    files = I18n.load_path.map{|p| File.expand_path(p)}
    files.map do |s|
      file = File.read(s) # for getting additional translation URL from the comments
      yaml = YAML.load(file) # for getting the actual language as well as all the keys
      link = file[/\#.*(http\S*)/,1] # the optional link to more translations
      
      s =~ /([^\/]*?)(?:-\d+(?:\.\d+)*)?(?:\/config)?(?:\/locales?\/)(?:(.*)\.)?([^\.]*)\.ya?ml$/
      register_keys LocaleFile.new(s, $1, $2, $3, yaml.keys.first, link, yaml)
    end
  end
  
  FileMappingsPath = File.join(root_dir, "config/translate.yml")
  FileMappings = YAML.load_path(FileMappingsPath) rescue {}
  def self.store_mappings
    File.open(FileMappingsPath, "w") {|f| f.puts(FileMappings.to_yaml) }
  end

  private
  def keys
    {locale => I18n.backend.send(:translations)[locale]}
  end
  
  def file_path
    File.join(Translate::Storage.root_dir, "config", "locales", "#{locale}.yml")
  end

  KeyFiles = {}
  def self.register_keys(locale_file)
    Keys.to_shallow_hash(locale_file.yaml).keys.each do |k|
      KeyFiles[k] = localefile
    end
    return locale_file
  end
  
end
