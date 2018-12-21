
describe "parse_automation_request" do
  let(:user) { FactoryBot.create(:user_with_group) }
  let(:inst) { "/System/Process/parse_automation_request" }

  it "for miq_provision request" do
    ws = MiqAeEngine.instantiate("#{inst}?request=vm_provision", user)
    expect(ws.root.attributes).to include(
      "target_component" => "VM",
      "target_class"     => "Lifecycle",
      "target_instance"  => "Provisioning"
    )
  end

  it "for vm_retired request" do
    ws = MiqAeEngine.instantiate("#{inst}?request=vm_retired", user)
    expect(ws.root.attributes).to include(
      "target_component" => "VM",
      "target_class"     => "Lifecycle",
      "target_instance"  => "Retirement"
    )
  end

  it "for vm_migrate request" do
    ws = MiqAeEngine.instantiate("#{inst}?request=vm_migrate", user)
    expect(ws.root.attributes).to include(
      "target_component" => "VM",
      "target_class"     => "Lifecycle",
      "target_instance"  => "Migrate"
    )
  end

  it "for orchestration_stack_retire request" do
    ws = MiqAeEngine.instantiate("#{inst}?request=orchestration_stack_retire", user)
    expect(ws.root.attributes).to include(
      "target_component" => "Orchestration",
      "target_class"     => "Lifecycle",
      "target_instance"  => "Retirement"
    )
  end

  it "for configured_system_provision request" do
    ws = MiqAeEngine.instantiate("#{inst}?request=configured_system_provision", user)
    expect(ws.root.attributes).to include(
      "target_component"     => "Configured_System",
      "target_class"         => "Lifecycle",
      "target_instance"      => "Provisioning",
      "ae_provider_category" => "infrastructure"
    )
  end
end
