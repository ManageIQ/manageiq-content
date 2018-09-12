require_domain_file
require File.join(ManageIQ::Content::Engine.root, 'content/automate/ManageIQ/Transformation/Infrastructure/VM/vmwarews.class/__methods__/utils.rb')

describe ManageIQ::Automate::Transformation::Infrastructure::VM::VMware::Utils do
  let(:host) { FactoryGirl.createe(:host) }

  let(:svc_model_host) { MiqAeMethodService::MiqAeServiceHost.find(host.id) }

  before do
    allow(TCPSocket).to receive(:open)
    allow(OpenSSL::SSL::SSLSocket).to receive(:connect)
  end

  context "#host_fingerprint" do
    
  end

  context "#vm_rename" do
    
  end
end
