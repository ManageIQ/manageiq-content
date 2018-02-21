require_domain_file
# This is the embedded method link, its only needed in the spec
# Not in the actual file and ensures that the symbols are satisfied
require File.join(ManageIQ::Content::Engine.root, 'content/automate/ManageIQ/System/CommonMethods/StateMachineMethods.class/__methods__/utility.rb')

describe ManageIQ::Automate::System::Request::Sample do
  let(:root_object) do
    Spec::Support::MiqAeMockObject.new(attributes)
  end

  let(:ae_service) do
    Spec::Support::MiqAeMockService.new(root_object).tap do |service|
      current_object = Spec::Support::MiqAeMockObject.new
      current_object.parent = root_object
      service.object = current_object
    end
  end

  let(:vm) { FactoryGirl.create(:vm, :name => 'fred') }
  # Since Automate methods only work with Service Model objects we have to wrap it
  # in the MiqAeMethodService
  let(:svc_vm) { MiqAeMethodService::MiqAeServiceVm.find(vm.id) }

  context "with vm object" do
    let(:attributes) do
      { 'var1' => 'A',
        'vm'   => svc_vm }
    end

    it "#vm start" do
      obj = described_class.new(ae_service)
      # This is optional so that we dont have to the run the embedded method spec
      # This is a stub and returns canned responses with no computational overhead
      #
      allow(ManageIQ::Automate::System::CommonMethods::StateMachineMethods::Utility).to receive(:normalize_name).with(vm.name).and_return("blah")

      expect(svc_vm).to receive(:start)

      obj.vm_start
    end

    it "#vm_start_ex" do
      obj = described_class.new(ae_service)
      # This creates a dummy instance that can be used to stub out methods
      util_obj = instance_double("ManageIQ::Automate::System::CommonMethods::StateMachineMethods::Utility")
      # When the caller creates a new instance we send back the dummy instance
      allow(ManageIQ::Automate::System::CommonMethods::StateMachineMethods::Utility).to receive(:new).with(vm.name).and_return(util_obj)
      # When that instance calls normalize we stub it and pass back a canned response
      allow(util_obj).to receive(:normalize).with(no_args).and_return("blah")

      expect(svc_vm).to receive(:start)

      obj.vm_start_ex
    end
  end
end
