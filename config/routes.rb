Rails.application.routes.draw do
  root 'home#index'
  
  # Add the route for Gmail authorization
  get 'gmail/messages', to: 'gmail_messages#fetch_messages'
end