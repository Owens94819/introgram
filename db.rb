require 'mysql2'

# Replace 'your_username', 'your_password', 'your_database' with your actual MySQL credentials
client = Mysql2::Client.new(
  host: 'mysql-2fa1f5f0-johnsonmach6-2d46.a.aivencloud.com',
  username: 'avnadmin',
  password: 'AVNS_t8K9draf2lVK7wHEvBK',
  database: 'defaultdb'
)

# Create a table named 'my_tb'
client.query("
  CREATE TABLE IF NOT EXISTS my_tb (
    id INT AUTO_INCREMENT PRIMARY KEY,
    column1 VARCHAR(255),
    column2 INT
  )
")

# Get a list of all tables in the database
tables = client.query('SHOW TABLES')

# Extract and print the table names
table_names = tables.map { |table| table.values.first }
puts "Tables in the database: #{table_names.join(', ')}"

# Close the connection when done
client.close
