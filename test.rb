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
  latest_account = connected_accounts.items.max_by { |account| account.created_at }
  latest_account
end


services = ["GMAIL"]
authorize_url_if_not_exists(services, composio_client)

connected_account = get_latest_connected_account("default", "GMAIL", composio_client)

actions_output = composio_client.actions.execute(
  action_id: "GMAIL_SEND_EMAIL",
  app_name: "GMAIL",
  entity_id: "default",
  connected_account_id: connected_account.id,
  input: {
    user_id: "me",
    recipient_email: "utkarshdix02@gmail.com",
    subject: "Job Application",
    body: "Dear Sir, Nice talking to you. Yours respectfully, John"
  }
)

puts "Action execution output: #{actions_output.inspect}"
