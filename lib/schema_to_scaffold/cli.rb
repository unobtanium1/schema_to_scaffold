require "schema_to_scaffold"
module SchemaToScaffold
  class CLI

    TABLE_OPTIONS = "\nOptions are:\n4 for table 4; (4..6) for table 4 to 6; [4,6] for tables 4 and 6; * for all Tables"

    def self.start(*args)
      ## Argument conditions
      opts = parse_arguments(args)

      if opts[:help]
        puts Help.message
        exit 0
      end

      ## looking for /schema\S*.rb$/ in user directory
      paths = Path.new(opts[:path])
      path = paths.choose unless opts[:path].to_s.match(/\.rb$/)

      ## Opening file
      path ||= opts[:path]
      begin
        data = File.open(path, 'r') { |f| f.read }
      rescue
        puts "\nUnable to open file '#{path}'"
        exit 1
      rescue Interrupt => e
        exit 1
      end

      ## Generate scripts from schema
      schema = Schema.new(data)
      schema_select_flag = opts[:output].nil?
      auto_output_flag = ! schema_select_flag

      begin
        raise if schema.table_names.empty?
        if schema_select_flag
          puts "\nLoaded tables:"
          schema.print_table_names
          puts TABLE_OPTIONS
          print "\nSelect a table: "
        end
      rescue
        puts "Could not find tables in '#{path}'"
        exit 1
      end

      #for auto-output default to *
      if schema_select_flag
        input = STDIN.gets.strip
      else
        input = "*"
      end

      begin
        tables = schema.select_tables(input)
        raise if tables.empty?
      rescue
        puts "Not a valid input. #{TABLE_OPTIONS}"
        exit 1
      rescue Interrupt => e
        exit 1
      end

      target = opts[:factory_girl] ? "factory_girl:model" : "scaffold"
      migration_flag = opts[:migration] ? true : false
      skip_no_migration_flag = opts[:skip_no_migration] ? true : false

      script = []
      script_hash={}
      #script_active_admin= [] #new:activeadmin
      #script_graphql = [] #new:graphql-rails-generator

      table_names = schema.table_names
      known_tables = []

      references_to_ignore = [ "CreatedBy", "UpdatedBy", "User",  "Updator", "Creator", "created", "updated"]


      tables.each do |table_id|
        scaffold_data = generate_script(schema, table_id, target, migration_flag, skip_no_migration_flag) 
        activeadmin_data = generate_script_active_admin(schema, table_id) #new:activeadmin
        graphql_data = generate_script_graphql_rails_generators(schema, table_id) #new:graphql-rails-generator

        script << scaffold_data
        script << activeadmin_data
        script << graphql_data
        script << "\n"

        #script_active_admin << activeadmin_data
        #script_graphql << graphql_data
        table_name = table_names[table_id].camelize.singularize
        known_tables << table_name
        script_hash[table_name] = {
          scaffold: scaffold_data, activeadmin: activeadmin_data, graphql_data: graphql_data, 
          references: (scaffold_data.join('').scan(/ (\w+):references/)).flatten.map{|x| x.camelize.singularize}.reject{|x| references_to_ignore.include? x}
        }
        #script_hash_references[table_name] = (scaffold_data.join('').scan(/ (\w+):references/)).flatten.map{|x| x.camelize.singularize}.reject{|x| [ "CreatedBy", "UpdatedBy"].include? x}
      end
      if auto_output_flag

        output_sequence = []
        seen_tables = []
        seen_table_at = {}
        resolve_level_count = 0
        remaining_references = {}

        script_hash_empty = !(script_hash.empty?)

        while script_hash_empty
          output_sequence << "\n\n# ************  RESOLVE LEVEL: #{resolve_level_count}   **************\n\n"
          
          puts "\n# resolve_level_count: #{resolve_level_count}\n"
          puts "\n\nSeen Tables: #{seen_tables.sort.join(', ')}\n"

          all_unresolved = true
          script_hash.each do |table_name, gen_data|

              references_for_table = gen_data[:references].reject{|x| !(known_tables.include? x)} #reject unknown tables

              all_references = (gen_data[:scaffold].join('').scan(/ (\w+):references/)).flatten.map{|x| x.camelize.singularize}.reject{|x| references_to_ignore.include? x}
              all_references_str = all_references.map{|x| (seen_table_at.key? x) ? [x, seen_table_at[x]] : [x,999] }.to_h.sort_by {|k,v| v}.to_h

              if references_for_table.empty?
                puts "creating #{table_name} base-table"
                seen_tables << table_name
                seen_table_at[table_name] = resolve_level_count
                output_sequence << gen_data[:scaffold]
                output_sequence << gen_data[:activeadmin]
                output_sequence << gen_data[:graphql_data]
                output_sequence << "# references: #{ all_references_str }"
                output_sequence << "\n\n"
                script_hash.delete(table_name) 
                all_unresolved = false
              else
                script_hash[table_name][:references] = references_for_table.reject{|x| seen_tables.include?(x) }
                puts "#{references_for_table.count} unresolved: \t#{table_name}  references:#{references_for_table }"
              end
          end
          
          resolve_level_count += 1

          if all_unresolved  #|| resolve_level_count > 10 
            puts "\n\n\nError, missing some references (#{all_unresolved}).\n\nSeen Tables: #{seen_tables.sort.join(', ')}\n"
            script_hash.each do |table_name, gen_data|
              references_for_table = gen_data[:references].reject{|x| known_tables.include? x}
              puts "#{references_for_table.count} unresolved: \t#{table_name}  references:#{references_for_table}"
            end
            #exit(1)
            #tack it on as is because screw it, what can you do?
            script_hash.each do |table_name, gen_data|
              all_references = (gen_data[:scaffold].join('').scan(/ (\w+):references/)).flatten.map{|x| x.camelize.singularize}.reject{|x| references_to_ignore.include? x}
              all_references_str = all_references.map{|x| (seen_table_at.key? x) ? [x, seen_table_at[x]] : [x,999] }.to_h.sort_by {|k,v| v}.to_h
              output_sequence << "# ****** WARNING: unresolved references *****\n\n"
              output_sequence << gen_data[:scaffold]
              output_sequence << gen_data[:activeadmin]
              output_sequence << gen_data[:graphql_data]
              output_sequence << "# references: #{ all_references_str }"
              output_sequence << "\n\n"
            end
            #breakout
            script_hash_empty= false
          end



        end
        output = output_sequence.join("")
        puts "\nScript for #{target}:\n\n"
        puts output
      else
        output = script.join("")
        #output_admin = script_active_admin.join(""); output += output_admin #new:activeadmin #new:activeadmin
        #output_graphql = script_graphql.join(""); output += output_graphql #new:graphql-rails-generator
        puts "\nScript for #{target}:\n\n"
        puts output
      end

      if opts[:clipboard]
        puts("\n(copied to your clipboard)")
        Clipboard.new(output).command
      end

      if auto_output_flag
        begin
          output_filename = opts[:output_path]
          default_output_dir = "output"
          Dir.mkdir(default_output_dir) unless File.exists?(default_output_dir)
          File.open(output_filename, "w") { |f| f.write output }
        rescue
          puts "\nUnable to write file '#{output_filename}'"
          exit 1
        rescue Interrupt => e
          exit 1
        end
      end
    end

    ##
    # Parses ARGV and returns a hash of options.
    def self.parse_arguments(argv)
      if argv_index = argv.index("-p")
        path = argv.delete_at(argv_index + 1)
        output_path = "output/#{path}"
        argv.delete('-p')
      end

      args = {
        clipboard: argv.delete('-c'),    # check for clipboard flag
        factory_girl: argv.delete('-f'), # factory_girl instead of scaffold
        migration: argv.delete('-m'),   # generate migrations
        skip_no_migration: argv.delete('-n'),   # skip '--no-migration'
        help: argv.delete('-h'),        # check for help flag
        output: argv.delete('-o'),        # check for help flag
        output_path: output_path,        # check for help flag
        path: path                      # get path to file(s)
      }

      if argv.empty?
        args
      else
        puts "\n------\nWrong set of arguments.\n------\n" 
        puts Help.message
        exit
      end
    end

    ##
    # Generates the rails scaffold script
    def self.generate_script(schema, table=nil, target, migration_flag, skip_no_migration_flag)
      schema = Schema.new(schema) unless schema.is_a?(Schema)
      return schema.to_script if table.nil?
      schema.table(table).to_script(target, migration_flag, skip_no_migration_flag)
    end

    #new:activeadmin
    def self.generate_script_active_admin(schema, table=nil)
      schema = Schema.new(schema) unless schema.is_a?(Schema)
      return schema.to_script_active_admin if table.nil?
      schema.table(table).to_script_active_admin
    end

    #new:graphql-rails-generator
    def self.generate_script_graphql_rails_generators(schema, table=nil)
      schema = Schema.new(schema) unless schema.is_a?(Schema)
      return schema.to_script_graphql_rails_generators if table.nil?
      schema.table(table).to_script_graphql_rails_generators
    end

  end
end
