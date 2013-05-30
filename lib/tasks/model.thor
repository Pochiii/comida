require "rubygems"
require "yaml"

class Model < Thor
  
  desc "generate", "Generate a script containing scaffolds"

  def generate(yamlfile)
    model = YAML::load(File.open(yamlfile))
    script = ""
    model.each do |table, data|
      script += "rails g scaffold \#{table}"
      data.each do |field, fieldtype|
        script += " \#{field}:\#{fieldtype}"
      end
      script += " && "
    end
    script += "rake db:migrate"
    puts script
  end

end
