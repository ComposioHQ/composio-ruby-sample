require 'composio'

# Initialize the Composio client
config = Composio::Configuration.default
config.debugging = true
composio_client = Composio::Client.new(config)

# Example usage of the Composio client
puts "Host: #{Composio.host}"

# Configure the Composio client
Composio.configure do |config|
  config.api_key = ENV['COMPOSIO_API_KEY']
end

composio_client.actions.execute(
  action_id: "GMAIL_SEND_EMAIL",
  app_name: "GMAIL",
  entity_id: "default",
  # Replace <connected_account_id> with your actual connected account ID
  connected_account_id: "<connected_account_id>",
  input: {
    user_id: "me",
    recipient_email: "utkarshdix02@gmail.com",
    subject: "Job Application",
    body: "Dear Sir, Nice talking to you. Yours respectfully, John"
  }
)