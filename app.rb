# encoding: UTF-8
require "sinatra/base"
require "sinatra/reloader" 

require 'capybara'
require 'selenium-webdriver'
require 'fileutils'
require "digest"

class App < Sinatra::Base

  configure :development do
    register Sinatra::Reloader
  end

  get "/thumbnail" do
    base_args = %w{headless no-sandbox disable-gpu}
    
    chrome_bin =  "/app/.apt/usr/bin/google-chrome"
    chrome_opts = chrome_bin ? { "chromeOptions" => { "binary" => chrome_bin, 'args' => base_args } } : {}

    Capybara.register_driver :chrome do |app|
      Capybara::Selenium::Driver.new(
        app,
        browser: :chrome,
        desired_capabilities: Selenium::WebDriver::Remote::Capabilities.chrome(chrome_opts)
      )
    end

    Capybara.default_driver = :chrome
    @session = Capybara::Session.new(:chrome)

    url = params[:url].to_s
    halt(404, "page not found") unless url =~ /^http:\/\/qiita.com/
    cache_key = Digest::SHA256.hexdigest(url) 

    cache_file = "/tmp/#{cache_key}.png"
    use_cache = FileTest.exist?(cache_file)

    begin
      if use_cache
        headers["Content-Type"] = "image/png"
        return open(cache_file).read
      else
        @session.visit(url)
        sleep 8 # waiting for getting assets 
        
        @session.driver.browser.manage.window.move_to(0, 0)
        @session.driver.browser.manage.window.resize_to(800, 1200)
        sleep 1
        
        @session.save_screenshot(cache_file)
        @session.driver.quit
        
        headers["Content-Type"] = "image/png"
        open(cache_file).read
        
      end
    rescue
      @session.driver.quit
      halt 403
    end
  end
  
end


