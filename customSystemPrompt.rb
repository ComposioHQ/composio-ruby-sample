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
  connected_account_id: "f2d76888-0362-42ef-900a-cc3e55d582b9",
  text: "Send email to utkarsh@composio.dev about hello world",
  system_prompt: "You are a helpful assistant that writes emails like a 5 year old kid",
  custom_description: "This action sends an email to the given recipient with the given subject and body."
)

puts "Actions Output: #{actions_output.inspect}"