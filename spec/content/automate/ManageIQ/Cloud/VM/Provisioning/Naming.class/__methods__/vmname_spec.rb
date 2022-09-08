require_domain_file

describe ManageIQ::Automate::Cloud::VM::Provisioning::Naming::VmName do
  let(:template) { FactoryBot.create(:template) }
  let(:provision) { MiqProvision.new }
  let(:root_object) { Spec::Support::MiqAeMockObject.new.tap { |ro| ro["miq_provision"] = provision } }
  let(:service) { Spec::Support::MiqAeMockService.new(root_object).tap { |s| s.object = {'vm_prefix' => "abc"} } }
  let(:classification) { FactoryBot.create(:classification, :tag => tag, :name => "environment") }
  let(:classification2) do
    FactoryBot.create(:classification,
                       :tag    => tag2,
                       :parent => classification,
                       :name   => "prod")
  end
  let(:tag) { FactoryBot.create(:tag, :name => "/managed/environment") }
  let(:tag2) { FactoryBot.create(:tag, :name => "/managed/environment/production") }

  context "#main" do
    before do
      allow(provision).to receive(:get_source).and_return(template)
    end

    it "no vm name from dialog" do
      provision.update!(:options => {:number_of_vms => 200})

      described_class.new(service).main

      expect(service.object['vmname']).to eq('abc$n{3}')
    end

    it "vm name from dialog" do
      provision.update!(:options => {:number_of_vms => 200, :vm_name => "drew"})

      described_class.new(service).main

      expect(service.object['vmname']).to eq('drew$n{3}')
    end

    it "use model and environment tag" do
      provision.update!(:options => {:number_of_vms => 200, :vm_tags => [classification2.id]})

      described_class.new(service).main

      expect(service.object['vmname']).to eq('abcpro$n{3}')
    end

    it "provisions single vm without name from dialog" do
      provision.update!(:options => {:number_of_vms => 1})

      described_class.new(service).main

      expect(service.object['vmname']).to eq('abc$n{3}')
    end

    it "provisions single vm with name from dialog" do
      provision.update!(:options => {:number_of_vms => 1, :vm_name => "jay"})

      described_class.new(service).main

      expect(service.object['vmname']).to eq('jay')
    end

    it "provisions single vm without name from dialog when number of vms is nil" do
      provision.update!(:options => {})

      described_class.new(service).main

      expect(service.object['vmname']).to eq('abc$n{3}')
    end

    it "provisions single vm with name from dialog when number of vms is nil" do
      provision.update!(:options => {:vm_name => "jay"})

      described_class.new(service).main

      expect(service.object['vmname']).to eq('jay')
    end
  end
end
