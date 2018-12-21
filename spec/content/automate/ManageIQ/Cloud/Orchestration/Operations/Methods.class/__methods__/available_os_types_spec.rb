require_domain_file

describe ManageIQ::Automate::Cloud::Orchestration::Operations::AvailableOsTypes do
  os_list = {'unknown' => '<Unknown>', 'linux' => 'Linux', 'windows' => 'Windows'}
  let(:service_template) do
    hw1 = FactoryBot.create(:hardware, :guest_os => 'windows')
    img1 = FactoryBot.create(:template_openstack, :uid_ems => 'uid1', :hardware => hw1)

    hw2 = FactoryBot.create(:hardware, :guest_os => 'linux')
    img2 = FactoryBot.create(:template_openstack, :uid_ems => 'uid2', :hardware => hw2)

    ems = FactoryBot.create(:ems_openstack, :miq_templates => [img1, img2])
    FactoryBot.create(:service_template_orchestration, :orchestration_manager => ems)
  end
  let(:root_hash) do
    { 'service_template' => MiqAeMethodService::MiqAeServiceServiceTemplate.find(service_template.id) }
  end
  let(:root_object) { Spec::Support::MiqAeMockObject.new(root_hash) }
  let(:ae_service) do
    Spec::Support::MiqAeMockService.new(root_object).tap do |service|
      current_object = Spec::Support::MiqAeMockObject.new
      current_object.parent = root_object
      service.object = current_object
    end
  end

  it "provides all os types and default to unknown" do
    described_class.new(ae_service).main

    expect(ae_service["values"]).to include(os_list)
    expect(ae_service["default_value"]).to eq('unknown')
  end

  it "provides all os types and auto selects the type based on the user selection of an image" do
    ae_service.root["dialog_param_userImageName"] = 'uid1'
    described_class.new(ae_service).main

    expect(ae_service["values"]).to include(os_list)
    expect(ae_service["default_value"]).to eq('windows')
  end
end
