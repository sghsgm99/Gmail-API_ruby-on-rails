require 'google/apis/gmail_v1'
require 'googleauth'

class GmailMessagesController < ApplicationController
  def fetch_messages
    client_id = ENV["GOOGLE_CLIENT_ID"]
    client_secret = ENV["GOOGLE_CLIENT_SECRET"]
    refresh_token = ENV["GOOGLE_REFRESH_TOKEN"]
    access_token = ENV["GOOGLE_ACCESS_TOKEN"]
    
    service = initialize_gmail_service(client_id, client_secret, refresh_token, access_token)

    begin
      opts = {
        max_results: 10,
        label_ids: ['INBOX'],
        q: 'from:no-reply@referrals.digitalocean.com'
      }

      result = service.list_user_messages('me', **opts)

      @messages = if result.messages
        result.messages.map do |msg|
          full_message = service.get_user_message('me', msg.id)
          extract_subject(full_message)
        end
      else
        []
      end
    rescue Google::Apis::AuthorizationError => e
      @error = "Authorization error: #{e}"
    rescue => e
      @error = "An error occurred: #{e}"
    end
  end

  private

  def initialize_gmail_service(client_id, client_secret, refresh_token, access_token)
    credentials = Signet::OAuth2::Client.new(
      authorization_uri: 'https://accounts.google.com/o/oauth2/auth',
      token_credential_uri: 'https://accounts.google.com/o/oauth2/token',
      client_id: client_id,
      client_secret: client_secret,
      access_token: access_token,
      refresh_token: refresh_token,
      scope: Google::Apis::GmailV1::AUTH_GMAIL_READONLY,
    )

    service = Google::Apis::GmailV1::GmailService.new
    service.authorization = credentials

    service
  end

  def extract_subject(message)
    headers = message.payload.headers
    subject_header = headers.find { |h| h.name == 'Subject' }
    subject_header ? subject_header.value : 'No Subject'
  end
end