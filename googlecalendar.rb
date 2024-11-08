require 'composio'

# Initialize the Composio client
config = Composio::Configuration.default
composio_client = Composio::Client.new(config)

# Example usage of the Composio client
puts "Host: #{Composio.host}"

# Configure the Composio client
Composio.configure do |config|
  config.api_key = ENV['COMPOSIO_API_KEY']
end

# Format for time is YYYY,MM,DD,HH,MM,SS
actions_output = composio_client.actions.execute(
  action_id: "GOOGLECALENDAR_FIND_EVENT",
  app_name: "googlecalendar",
  entity_id: "default",
  connected_account_id: "<googlecalendar_connected_account_id>",
  input: {
    "timeMin" => "2024,11,09,00,00,00",
    "timeMax" => "2024,11,09,23,59,59"
  }
)

puts "Actions Output: #{actions_output.inspect}"
