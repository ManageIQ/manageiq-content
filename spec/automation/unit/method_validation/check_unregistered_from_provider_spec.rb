describe "check_unregistered_from_provider Method Validation" do
  before(:each) do
    @user = FactoryBot.create(:user_with_group)
    @zone = FactoryBot.create(:zone)
    @ems  = FactoryBot.create(:ems_vmware, :zone => @zone)
    @host = FactoryBot.create(:host)
    @vm   = FactoryBot.create(:vm_vmware,
                               :name => "testVM", :raw_power_state => "poweredOff",
                               :registered => false)
    @ae_state   = {'vm_removed_from_provider' => true}
    @ins  = "/Infrastructure/VM/Retirement/StateMachines/Methods/CheckRemovedFromProvider"
  end

  let(:ws) { MiqAeEngine.instantiate("#{@ins}?Vm::vm=#{@vm.id}&ae_state_data=#{URI.escape(YAML.dump(@ae_state))}", @user) }

  it "returns 'ok' if the vm is not connected to a ems" do
    expect(ws.root['vm']['registered']).to  eql(false)
    expect(ws.root['ae_result']).to         eql("ok")
  end

  it "returns 'retry' if the vm is still connected to ems" do
    @vm.update_attributes(:host => @host, :ems_id => @ems.id,
                          :registered => true)
    allow_any_instance_of(Vm).to receive(:refresh_ems)
    expect(ws.root['ae_result']).to eql("retry")
    expect(ws.root['vm']['registered']).to eq(true)
  end
end
