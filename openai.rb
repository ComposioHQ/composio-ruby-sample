require 'composio'
require 'openai'

# Initialize the Composio client
config = Composio::Configuration.default
composio_client = Composio::Client.new(config)

# Configure the Composio client
Composio.configure do |config|
  config.api_key = ENV['COMPOSIO_API_KEY']
end

def authorize_url_if_not_exists(services, composio = Composio)
  inactive_services = []
  services.each do |service|
    begin
      connections = composio.connections.list(user_uuid: "default", app_names: service, page: 1, page_size: 10000, show_disabled: false)
      latest_connection = connections.items.max_by { |connection| connection.created_at }
      
      if latest_connection.nil? || latest_connection.status != 'ACTIVE'
        app = composio.apps.get_details(app_name: service)
        integration = composio.integrations.create_integration(
          name: service,
          app_id: app.app_id,
          auth_scheme: "OAUTH2",
          use_composio_auth: true,
          force_new_integration: false
        )
        puts "Integration created with label: #{integration.name} #{service} -> #{integration}"

        connection = composio.connections.initiate(
          integration_id: integration.id,
          user_uuid: "default"
        )
        inactive_services << { service: service, url: connection.redirect_url, connected_account_id: connection.connected_account_id }
      end
    rescue => e
      raise e
    end
  end

  inactive_services.each do |service|
    puts "Please open this link to complete authorization for #{service[:service]}: #{service[:url]}"
    connected_account_id = service[:connected_account_id]
    status = nil
    timeout = 60
    start_time = Time.now

    until status == 'ACTIVE' || (Time.now - start_time) > timeout
      sleep(5)  # Poll every 5 seconds
      connected_account = composio.connections.get(connected_account_id: connected_account_id)
      status = connected_account.status
    end

    if status == 'ACTIVE'
      puts "#{service[:service]} is now active."
    else
      puts "Timeout reached for #{service[:service]}. Please try again."
    end
  end
end

def get_latest_connected_account(entity_id, app_name, composio_client)
  connected_accounts = composio_client.connections.list(user_uuid: entity_id, app_names: app_name, page: 1, page_size: 10000, show_disabled: false)
  connected_accounts.items.max_by { |account| account.created_at }
end

services = ["GMAIL"]
authorize_url_if_not_exists(services, composio_client)

connected_account = get_latest_connected_account("default", "GMAIL", composio_client)

action_details = composio_client.actions.get_action_by_id(action_id: "GMAIL_SEND_EMAIL")

# TODO: For complete compatibility, we need to add support for all the different types of parameters that are supported by
# OpenAPI like allOf, anyOf, oneOf, not, etc.
def convert_action_to_openai_function(action_details)
  openai_function = {
    name: action_details.name,
    description: action_details.description,
    parameters: {
      type: "object",
      properties: {},
      required: []
    }
  }

  action_details.parameters[:properties].each do |key, param|
    openai_function[:parameters][:properties][key] = {
      type: param[:type].downcase,
      description: param[:description]
    }
    
    openai_function[:parameters][:properties][key][:default] = param[:default] if param.key?(:default)
    openai_function[:parameters][:properties][key][:examples] = param[:examples] if param.key?(:examples)
    
    if param[:type].downcase == "object" && param.key?(:properties)
      openai_function[:parameters][:properties][key][:properties] = {}
      param[:properties].each do |nested_key, nested_param|
        openai_function[:parameters][:properties][key][:properties][nested_key] = {
          type: nested_param[:type].downcase,
          description: nested_param[:description]
        }
      end
      openai_function[:parameters][:properties][key][:required] = param[:required] if param.key?(:required)
    end
  end

  openai_function[:parameters][:required] = action_details.parameters[:required] if action_details.parameters.key?(:required)

  openai_function
end

openai_function = convert_action_to_openai_function(action_details)
openai_client = OpenAI::Client.new(
  access_token: ENV['OPENAI_API_KEY'],
  log_errors: true
)

chat_messages = [
  { role: "system", content: "You are a helpful assistant that can send emails." },
  { role: "user", content: "Please send an email to test@example.com with the subject 'Test Email' and body 'This is a test email sent using OpenAI function calls.'" }
]

response = openai_client.chat(
  parameters: {
    model: "gpt-4-turbo",
    messages: chat_messages,
    functions: [openai_function],
    function_call: "auto"
  }
)

chat_messages.each do |message|
  puts "#{message[:role].capitalize}: #{message[:content]}"
end


function_call = response.dig("choices", 0, "message", "function_call")

if function_call && function_call["name"] == "GMAIL_SEND_EMAIL"
  args = JSON.parse(function_call["arguments"])
  puts "OpenAI Assistant: Sending email with the following details:"
  puts JSON.pretty_generate(args)
else
  puts "No email sent. OpenAI response:"
  puts JSON.pretty_generate(response)
end
