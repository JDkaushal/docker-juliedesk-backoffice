Rails.application.config.middleware.use OmniAuth::Builder do
  provider :google_oauth2, ENV["GOOGLE_CLIENT_ID"], ENV["GOOGLE_CLIENT_SECRET"], {
      access_type: 'offline',
      prompt: "consent",
      scope: 'https://www.googleapis.com/auth/userinfo.profile https://mail.google.com https://www.googleapis.com/auth/gmail.compose https://www.googleapis.com/auth/gmail.modify'
  }
end