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

actions_output = composio_client.actions.execute(
  action_id: "GMAIL_SEND_EMAIL",
  app_name: "gmail",
  entity_id: "default",
  connected_account_id: "1edd138c-b589-45f3-8d9f-bdcd498c011b",
  text: "Write email to utkarshdix02@gmail.com in professional serious tone"
)

puts "Actions Output: #{actions_output.inspect}"
