if Rails.env.production?
  Rails.application.config.force_ssl = false
  Rails.application.config.log_level = :info
  Rails.application.config.public_file_server.enabled = true
end
