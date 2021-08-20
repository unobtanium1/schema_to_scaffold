module SchemaToScaffold
  require 'active_support/inflector'
  ##
  # fetch table names and convert them to a scaffold syntax

  class Table

    attr_reader :attributes, :name

    def initialize(name, attributes)
      @name, @attributes = name, attributes
    end

    def to_script(target, migration_flag)
      begin
        attributes_list = attributes.map(&:to_script).reject { |x| x.nil? || x.empty? }.join(' ')
      rescue => e
        puts "\n ---------------------------------------------"
        puts e.message
        puts "Table \n\n\n #{self.inspect} \n\n\n"
        puts "\n ---------------------------------------------"
      end
      script = []
      script << "rails generate #{target} #{modelize(name)} #{attributes_list}"
      script << " --no-migration" unless migration_flag or skip_no_migration_flag
      script << "\n\n"
      script
    end

    def to_script_active_admin
      script = []
      script << "rails generate active_admin:resource #{modelize(name)}"
      script << "\n\n"
      script
    end

    #new:activeadmin
    def to_script_graphql_rails_generators
      script = []
      script << "rails generate gql:model_type  #{modelize(name)}"
      script << "rails generate gql:input #{modelize(name)}"
      script << "rails generate gql:mutation #{modelize(name)}"
      script << "rails generate gql:search_object #{modelize(name)}"
      script << "\n\n"
      script
    end
   

    def self.parse(table_data)
      return unless name = table_data[/table "([^"]+?)"/]
      name = $1
      table_fields = table_fields_of(table_data)
      Table.new(name, table_fields)
    end

    private
    def self.table_fields_of(table_data)
      table_data.lines.to_a.select { |line| line =~ /t\.(?!index)\w+/ }.map { |att| Attribute.parse(att) }
    end

    private

    def modelize(string)
      string.camelize.singularize
    end

  end
end
