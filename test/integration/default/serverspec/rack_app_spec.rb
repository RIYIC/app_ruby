require 'spec_helper'

describe "Passenger Watchdog" do

    c = command('ps -auxwwwwf')
    
    it "has a running service 'Passenger Watchdog'" do
        expect(c.stdout).to match /passenger\swatchdog/i
    end
end

describe "nginx" do

    it "is listening on port tcp/80 of 0.0.0.0" do
        expect(port(80)).to be_listening.on('0.0.0.0').with('tcp')
    end

end

domain = $node["app"]["ruby"]["rack_apps"][0]["domain"]
user = $node["app"]["ruby"]["rack_apps"][0]["owner"]
target_path = $node["app"]["ruby"]["rack_apps"][0]["target_path"]

describe "Example Rack app in domain #{domain}" do

    describe "Get dynamic page from app (#{domain})" do
    
        c = command("curl -L -H 'Host:#{domain}' 127.0.0.1/home")

        it "connection should not return error" do
            expect(c.exit_status) == 0
        end

        it "should return a determined dynamic content" do
        
            expect(c.stdout).to match /dynamic test page/
        end

    end

    describe "Get static page" do
        c = command("curl -L -H 'Host:#{domain}' 127.0.0.1/test.html")

        it "connection should not return error" do
            expect(c.exit_status) == 0
        end

        it "should return a static page" do
            expect(c.stdout).to match /test/
        end
    end


    describe file("#{target_path}") do

        it {should be_owned_by user}
        
    end


    describe "Passenger #{domain} proccess" do

        c = command("ps -auxwwwwf |egrep 'Passenger (RackApp|RubyApp)'|fgrep '#{target_path.gsub!(/\/$/,'')}'")

        it "must be running as app user #{user}" do
            expect(c.stdout).to match /^#{user}/
        end

    end


end
