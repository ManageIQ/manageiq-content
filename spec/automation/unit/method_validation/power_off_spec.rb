require File.expand_path(File.join(File.dirname(__FILE__), '..', '..',
                                   '..', 'spec_helper'))

describe "power_off Method Validation" do
  before(:each) do
    @zone       = FactoryBot.create(:zone)
    @user       = FactoryBot.create(:user_with_group)
    @ems        = FactoryBot.create(:ems_vmware, :zone => @zone)
    @host       = FactoryBot.create(:host)
    @vm         = FactoryBot.create(:vm_vmware, :host => @host,
                 :ems_id => @ems.id, :name => "testVM2", :raw_power_state => "poweredOn")
  end

  let(:ws) { MiqAeEngine.instantiate("/Infrastructure/VM/Retirement/StateMachines/Methods/PowerOff?Vm::vm=#{@vm.id}", @user) }

  it "powers off a vm in a 'powered on' state" do
    ws

    expect(MiqQueue.exists?(:method_name => 'stop', :instance_id => @vm.id,
    :role => 'ems_operations')).to be_truthy
  end

  it "does not queue any operation for a vm in 'powered_off' state" do
    @vm.update_attribute(:raw_power_state, "poweredOff")

    ws

    expect(MiqQueue.exists?(:method_name => 'stop', :instance_id => @vm.id, :role => 'ems_operations')).to be_falsey
  end
end
