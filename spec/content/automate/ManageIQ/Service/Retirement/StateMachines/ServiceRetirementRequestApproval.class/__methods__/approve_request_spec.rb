require_domain_file

describe ManageIQ::Automate::Service::Retirement::StateMachines::ServiceRetirementRequestApproval::ApproveRequest do
  let(:svc_request) { MiqAeMethodService::MiqAeServiceMiqProvisionRequest.find(request.id) }
  let(:request)     { FactoryBot.create(:miq_provision_request, :with_approval) }
  let(:root_object) { Spec::Support::MiqAeMockObject.new(root_hash) }
  let(:root_hash)   { { 'miq_request' => svc_request } }

  let(:ae_service) do
    Spec::Support::MiqAeMockService.new(root_object).tap do |service|
      current_object = Spec::Support::MiqAeMockObject.new
      current_object.parent = root_object
      current_object['approval_type'] = 'auto'
      service.object = current_object
    end
  end

  it 'approves request' do
    expect(svc_request).to(receive(:approve).with('admin', 'Auto-Approved'))
    described_class.new(ae_service).main
  end

  it 'does not approve request' do
    ae_service.object['approval_type'] = nil
    expect { described_class.new(ae_service).main }.to raise_error('Not Auto-Approved')
  end
end
