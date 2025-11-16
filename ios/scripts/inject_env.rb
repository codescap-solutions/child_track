#!/usr/bin/env ruby

# Script to inject Google Maps API Key from .env into AppDelegate.swift
# This is called automatically from Podfile post_install hook

def inject_api_key(ios_dir = nil)
  # Get iOS directory - use provided path or calculate from script location
  if ios_dir.nil?
    # When loaded from Podfile, __FILE__ will be this script's path
    script_dir = File.dirname(File.expand_path(__FILE__))
    ios_dir = File.dirname(script_dir)
  end
  
  project_root = File.dirname(ios_dir)
  env_file = File.join(project_root, '.env')
  app_delegate_file = File.join(ios_dir, 'Runner/AppDelegate.swift')
  
  # Read .env file
  unless File.exist?(env_file)
    puts "Warning: .env file not found at #{env_file}"
    return
  end
  
  # Extract GOOGLE_MAPS_API_KEY
  api_key = nil
  File.readlines(env_file).each do |line|
    if line.start_with?('GOOGLE_MAPS_API_KEY=')
      api_key = line.split('=', 2)[1].strip
      break
    end
  end
  
  if api_key.nil? || api_key.empty?
    puts "Warning: GOOGLE_MAPS_API_KEY not found in .env file"
    return
  end
  
  # Read AppDelegate.swift
  unless File.exist?(app_delegate_file)
    puts "Error: AppDelegate.swift not found at #{app_delegate_file}"
    return
  end
  
  content = File.read(app_delegate_file)
  
  # Replace the API key in the fallback value
  # Pattern: "AIzaSy..." (the fallback key)
  content.gsub!(/("AIzaSy[^"]+")/, "\"#{api_key}\"")
  
  # Also update if using environment variable pattern
  # This ensures the fallback is updated
  File.write(app_delegate_file, content)
  
  puts "Successfully injected Google Maps API Key from .env into AppDelegate.swift"
end

# Run if called directly (not loaded from Podfile)
if __FILE__ == $0
  inject_api_key
end

