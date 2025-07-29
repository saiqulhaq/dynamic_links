module DynamicLinks
  module Generators
    class AddKgsMigrationGenerator < Rails::Generators::Base
      source_root File.expand_path('templates', __dir__)

      def create_migration_file
        timestamp = Time.now.utc.strftime("%Y%m%d%H%M%S")
        migration_filename = "#{timestamp}_add_available_to_shortened_urls.rb"
        migration_template = File.read(File.join(self.class.source_root, "migration_template.rb"))

        create_file "db/migrate/#{migration_filename}", migration_template
      end
    end
  end
end

