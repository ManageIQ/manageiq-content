require_domain_file

describe ManageIQ::Automate::Cloud::VM::Retirement::Email::VmRetirementEmails do
  let(:user)       { FactoryGirl.create(:user_with_email_and_group) }
  let(:ems)        { FactoryGirl.create(:ems_amazon_with_authentication, :tenant => Tenant.root_tenant) }
  let(:vm)         { FactoryGirl.create(:vm_amazon, :evm_owner => user, :ems_id => ems.id) }
  let(:svc_vm)     { MiqAeMethodService::MiqAeServiceVm.find(vm.id) }
  let(:event)      { 'vm_retire_warn' }
  let(:signature)  { 'test_signature' }
  let(:from)       { 'from_email@examle.com' }
  let(:root_hash)  {}

  let(:root_object) do
    Spec::Support::MiqAeMockObject.new(root_hash)
  end

  let(:ae_service) do
    Spec::Support::MiqAeMockService.new(root_object).tap do |service|
      current_object = Spec::Support::MiqAeMockObject.new
      current_object.parent = root_object
      current_object['event'] = event
      current_object['signature'] = signature
      current_object['from_email_address'] = from
      service.object = current_object
    end
  end

  let(:vm_retire_warn) do
    vm_name = vm['name']
    subject = "VM Retirement Warning for #{vm_name}"

    body = "Hello, "
    body += "<br><br>Your virtual machine: [#{vm_name}] will be retired on [#{vm['retires_on']}]."
    body += "<br><br>If you need to use this virtual machine past this date please request an"
    body += "<br><br>extension by contacting Support."
    body += "<br><br> Thank you,"
    body += "<br> #{signature}"

    [subject, body]
  end

  let(:vm_retire_extend) do
    vm_name = vm['name']
    subject = "VM Retirement Extended for #{vm_name}"

    body = "Hello, "
    body += "<br><br>Your virtual machine: [#{vm_name}] will now be retired on [#{vm['retires_on']}]."
    body += "<br><br>If you need to use this virtual machine past this date please request an"
    body += "<br><br>extension by contacting Support."
    body += "<br><br> Thank you,"
    body += "<br> #{signature}"

    [subject, body]
  end

  let(:vm_entered_retirement) do
    vm_name = vm['name']
    subject = "VM #{vm_name} has entered retirement"

    body = "Hello, "
    body += "<br><br>Your virtual machine named [#{vm_name}] has been retired."
    body += "<br><br>You will have up to 3 days to un-retire this VM. Afterwhich time the VM will be deleted."
    body += "<br><br> Thank you,"
    body += "<br> #{signature}"

    [subject, body]
  end

  let(:vm_retired) do
    vm_name = vm['name']
    subject = "VM Retirement Alert for #{vm_name}"

    body = "Hello, "
    body += "<br><br>Your virtual machine named [#{vm_name}] has been retired."
    body += "<br><br> Thank you,"
    body += "<br> #{signature}"

    [subject, body]
  end

  context 'vm_from_evm method' do
    it 'raises exception without VM' do
      expect { described_class.new(ae_service).main }.to raise_error('User not specified')
    end

    context '#vm in object' do
      it 'returns vm' do
        ae_service['vm'] = svc_vm
        expect(described_class.new(ae_service).send(:vm_from_evm).id).to(eq(svc_vm.id))
      end
    end

    context '#vm_id in object' do
      let(:root_hash)  { { 'vm_id' => svc_vm.id} }

      it 'returns vm' do
        ae_service['vm_id'] = svc_vm.id
        expect(described_class.new(ae_service).send(:vm_from_evm).id).to(eq(svc_vm.id))
      end
    end

    context '#vm in root object' do
      let(:root_hash) { { 'vm' => svc_vm} }

      it 'returns vm' do
        expect(described_class.new(ae_service).send(:vm_from_evm).id).to(eq(svc_vm.id))
      end
    end

    context '#vm_id in root object' do
      let(:root_hash)  { { 'vm_id' => svc_vm.id} }

      it 'returns vm' do
        expect(described_class.new(ae_service).send(:vm_from_evm).id).to(eq(svc_vm.id))
      end
    end

    context '#vm in miq_provision' do
      let(:options)       { { :src_vm_id => vm.id } }
      let(:provision)     { FactoryGirl.create(:miq_provision, :options => options, :vm => vm) }
      let(:svc_provision) { MiqAeMethodService::MiqAeServiceMiqProvision.find(provision.id) }
      let(:root_hash)     { { 'miq_provision' => svc_provision } }

      it 'returns vm' do
        expect(described_class.new(ae_service).send(:vm_from_evm).id).to(eq(svc_vm.id))
      end
    end

    context '#vm in miq_provision_request' do
      let(:request)     { FactoryGirl.create(:miq_provision_request) }
      let(:svc_request) { MiqAeMethodService::MiqAeServiceMiqRequest.find(request.id) }
      let(:root_hash)   { { 'miq_provision_request' => svc_request } }

      it 'returns vm' do
        allow(svc_request).to(receive(:vm).and_return(svc_vm))
        expect(described_class.new(ae_service).send(:vm_from_evm).id).to(eq(svc_vm.id))
      end
    end
  end

  context 'sends emails' do
    let(:root_hash) { { 'vm' => svc_vm } }

    it '#vm_retire_warn' do
      subject, body = vm_retire_warn
      expect(ae_service).to(receive(:execute).with('send_email', user.email, from, subject, body))
      described_class.new(ae_service).main
    end

    it '#vm_retire_extend' do
      subject, body = vm_retire_extend
      ae_service['event'] = 'vm_retire_extend'
      expect(ae_service).to(receive(:execute).with('send_email', user.email, from, subject, body))
      described_class.new(ae_service).main
    end

    it '#vm_entered_retirement' do
      subject, body = vm_entered_retirement
      ae_service['event'] = 'vm_entered_retirement'
      expect(ae_service).to(receive(:execute).with('send_email', user.email, from, subject, body))
      described_class.new(ae_service).main
    end

    it '#vm_retired' do
      subject, body = vm_retired
      ae_service['event'] = 'vm_retired'
      expect(ae_service).to(receive(:execute).with('send_email', user.email, from, subject, body))
      described_class.new(ae_service).main
    end

    context '#VM without owner' do
      let(:vm) { FactoryGirl.create(:vm_amazon, :ems_id => ems.id) }

      it '#vm_retire_warn' do
        vm.attributes['evm_owner_id'] = nil
        to_email_address = 'to_email@example.com'
        ae_service.object['to_email_address'] = to_email_address

        subject, body = vm_retire_warn
        expect(ae_service).to(receive(:execute).with('send_email', to_email_address, from, subject, body))
        described_class.new(ae_service).main
      end
    end
  end
end
