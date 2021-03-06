require 'chefspec'

describe 'prosody::default' do
  let(:chef_runner) do
    cb_path = [Pathname.new(File.join(File.dirname(__FILE__), '..', '..')).cleanpath.to_s, 'spec/support/cookbooks']
    ChefSpec::ChefRunner.new(:cookbook_path => cb_path)
  end

  let(:chef_run) do
    chef_runner.converge 'prosody::default'
  end

  it 'installs prosody' do
    expect(chef_run).to install_package 'prosody'
  end
  
  it 'places localhost example config in conf.avail' do
    expect(chef_run).to create_file_with_content "/etc/prosody/conf.avail/localhost.cfg.lua", "VirtualHost \"localhost\""
  end
  
  it 'downloads plugins into modules directory' do
    chef_runner.node.set['prosody']['plugins'] = {
      "pubsub" => {
        "modules/mod_pubsub.lua" => "http://example.org/mod_pubsub.lua",
        "util/pubsub.lua" => "http://example.org/util/pubsub.lua"
      }
    }
    chef_run = chef_runner.converge 'prosody::default'
    expect(chef_run).to create_remote_file("/usr/lib/prosody/modules/mod_pubsub.lua").with(:source => "http://example.org/mod_pubsub.lua")
    expect(chef_run).to create_remote_file("/usr/lib/prosody/util/pubsub.lua").with(:source => "http://example.org/util/pubsub.lua")
  end
  
  it 'places a config for every VirtualHost in conf.avail' do
    chef_runner.node.set['prosody']['hosts'] = {
      "example.org" => {}
    }
    chef_run = chef_runner.converge 'prosody::default'
    expect(chef_run).to create_file_with_content "/etc/prosody/conf.avail/example.org.cfg.lua", "VirtualHost \"example.org\""
  end
  
  it 'links all enabled configs into conf.d' do
    chef_runner.node.set['prosody']['conf_enabled'] = [
      "example.org"
    ]
    expect(chef_run).to create_link "/etc/prosody/conf.d/example.org.cfg.lua"
  end
  
  it 'configures prosody' do
    expect(chef_run).to create_file "/etc/prosody/prosody.cfg.lua"
  end
  
  it 'enables and starts prosody' do
    expect(chef_run).to start_service "prosody"
    expect(chef_run).to set_service_to_start_on_boot "prosody"
  end
end
