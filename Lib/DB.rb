require 'mysql2'

puts 1

# Connect to MySQL
client = Mysql2::Client.new(
  host: 'localhost',
  username: 'root',
  password: '',
  database: 'localstorage'
)

puts 2

# Execute a simple query
results = client.query('SELECT * FROM your_table')

# Process the query results
results.each do |row|
  puts "Column1: #{row['column1']}, Column2: #{row['column2']}"
end

# Close the connection
client.close