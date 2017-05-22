require_domain_file

describe ManageIQ::Automate::Cloud::Orchestration::Provisioning::Email::ServiceTemplateProvisionRequestApproved do
  let(:miq_request)             { FactoryGirl.create(:service_template_provision_request, :requester => user) }
  let(:user)                    { FactoryGirl.create(:user_with_group, :email => requester_email) }
  let(:miq_server)              { FactoryGirl.create(:miq_server, :ipaddress => miq_server_ipadress) }
  let(:svc_model_miq_server)    { MiqAeMethodService::MiqAeServiceMiqServer.find(miq_server.id) }
  let(:svc_model_miq_request)   { MiqAeMethodService::MiqAeServiceMiqRequest.find(miq_request.id) }
  let(:root_hash)               { {} }
  let(:to_email_address)        { 'to_email_address@email.com' }
  let(:from_email_address)      { 'from_email_address@email.com' }
  let(:requester_email)         { 'requester_email_address@email.com' }
  let(:owner_email)             { 'owner_email_address@email.com' }
  let(:signature)               { 'signature' }
  let(:miq_server_ipadress)     { 'miq_server_ip_adress.com' }
  let(:subject)                 { "Request ID #{miq_request.id} - Your Service provision request was Approved" }

  let(:body) do
    "Hello, <br>Your Service provision request was approved. If Service provisioning is successful you"\
    " will be notified via email when the Service is available.<br><br>Approvers notes: #{miq_request.reason}"\
    "<br><br>To view this Request go to: <a href='https://#{miq_server_ipadress}/miq_request/show/#{miq_request.id}"\
    "'>https://#{miq_server_ipadress}/miq_request/show/#{miq_request.id}</a><br><br> Thank you,<br> #{signature}"
  end

  let(:root_object) do
    obj = Spec::Support::MiqAeMockObject.new(root_hash)
    obj['miq_request'] = svc_model_miq_request
    obj['miq_server']  = svc_model_miq_server
    obj
  end

  let(:ae_service) do
    Spec::Support::MiqAeMockService.new(root_object).tap do |service|
      current_object                       = Spec::Support::MiqAeMockObject.new
      current_object.parent                = root_object
      current_object['to_email_address']   = to_email_address
      current_object['from_email_address'] = from_email_address
      current_object['signature']          = signature
      service.object                       = current_object
    end
  end

  context "with request object" do
    it "create the correct email" do
      allow(ae_service).to receive(:options) { {:owner_email => owner_email} }
      expect(ae_service).to receive(:execute). with(
        :send_email,
        to_email_address,
        from_email_address,
        subject,
        body
      )
      described_class.new(ae_service).main
    end
  end

  context "without request object" do
    let(:root_object) { Spec::Support::MiqAeMockObject.new(root_hash) }

    it "should raise error" do
      expect { described_class.new(ae_service).main }.to raise_error('miq_request is missing')
    end
  end
end
