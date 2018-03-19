require 'rails/generators/base'

module Capistrano
  module Sneakers
    module Monit
      module Generators
        class TemplateGenerator < Rails::Generators::Base

          namespace "capistrano:sneakers:monit:template"
          desc "Create local monitrc.erb, and erb files for monitored processes for customization"
          source_root File.expand_path('../templates', __FILE__)
          argument :templates_path, type: :string,
            default: "config/deploy/templates",
            banner: "path to templates"

          def copy_template
            copy_file "sneakers_monit.conf.erb", "#{templates_path}/sneakers_monit.erb"
          end

        end
      end
    end
  end
end
