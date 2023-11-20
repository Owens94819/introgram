require 'mysql2'
require 'yaml'
require 'active_record'
puts 88

# Load database configuration from YAML file in the config directory
db_config = YAML.load_file('config/database.yml')
puts 88

# Connect to the database
ActiveRecord::Base.establish_connection(db_config['development'])
puts 88
# # Connect to MySQL
# client = Mysql2::Client.new(
#   host: 'localhost',
#   username: 'root',
#   password: '',
#   database: 'localstorage'
# )

# # Execute a simple query
# results = client.query('SELECT * FROM your_table')

# # Process the query results
# results.each do |row|
#   puts "Column1: #{row['column1']}, Column2: #{row['column2']}"
# end

# # Close the connection
# client.close