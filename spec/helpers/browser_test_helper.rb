module Watir
  VERSION = '6.19.1'
end

class BrowserTestHelper
  def initialize(port:)
    @port = port
  end

  def remove_server_pid
    lingering = `ls tmp/pids`.strip.eql?('server.pid')
    system('rm -v tmp/pids/server.pid') if lingering
  end

  def launch_rails_server
    remove_server_pid
    fork { exec("bundle exec rails s -p #{@port}") }
    running = true
    while running
      rails_proc_id = `lsof -t -i:#{@port}`
      running = false unless rails_proc_id.presence.nil?
      StringUtil.log('Waiting for Rails server to start up', :yellow)
      sleep 1
    end
  end

  def kill_rails_server
    rails_proc_id = `lsof -t -i:#{@port}`
    `kill -9 #{rails_proc_id}`
    rails_proc_id = `lsof -t -i:#{@port}`

    counter = 2
    running = true
    while running
      running = false if rails_proc_id.presence.nil?
      StringUtil.log('Rails server shut down', :yellow)
      counter -= 1
      running = false if counter == 0
      sleep 1
    end

    remove_server_pid
  end

  def launch_browser
    browser_options = { args: %w[--window-size=1920,1080] }
    # headless = ENV['HEADLESS'].eql?('false') ? false : true
    @browser = Watir::Browser.new(:chrome, headless: false, options: browser_options)
  end

  def application_root_url
    "http://localhost:#{@port}"
  end

  def learner_sign_in_url
    [application_root_url, 'learners', 'sign_in'].join('/')
  end
end
