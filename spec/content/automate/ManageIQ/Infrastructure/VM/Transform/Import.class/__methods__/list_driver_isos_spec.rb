require_domain_file

describe ManageIQ::Automate::Infrastructure::VM::Transform::Import::ListDriverIsos do

  let(:root_object) do
    Spec::Support::MiqAeMockObject.new(
      'dialog_provider' => provider.id.to_s
    )
  end

  let(:ae_service) do
    Spec::Support::MiqAeMockService.new(root_object).tap do |service|
      current_object = Spec::Support::MiqAeMockObject.new
      current_object.parent = root_object
      service.object = current_object
    end
  end

  context 'with ISO domain added' do
    let!(:provider) { FactoryGirl.create(:ems_redhat, :with_clusters, :iso_datastore => iso_datastore) }
    let!(:iso_datastore) do
      iso_images = %w(
        virtio-win-1.9.0.iso
        virtio-win-1.9.0_amd64.vfd
        RHEV-toolsSetup_3.5_15.iso
        RHEV-toolsSetup_4.0_7.iso
        random-image.iso
        RHEV-toolsSetup_4.1_5.iso
        oVirt-toolsSetup-4.0-1.fc24.iso
        oVirt-toolsSetup-4.1-3.fc24.iso
        another-random-image.iso
        rhev-tools-setup.iso
        oVirt-toolsSetup-4.2-4.fc25.iso
      ).map { |iso| FactoryGirl.create(:iso_image, :name => iso) }
      FactoryGirl.create(:iso_datastore, :iso_images => iso_images)
    end

    it "should list iso images of selected infra provider's iso datastore" do
      described_class.new(ae_service).main

      expect(ae_service.object['sort_by']).to eq(:description)
      expect(ae_service.object['data_type']).to eq(:string)
      expect(ae_service.object['required']).to eq(true)

      isos = { nil => '-- select drivers ISO from list --' }
      %w(
        RHEV-toolsSetup_3.5_15.iso
        RHEV-toolsSetup_4.0_7.iso
        RHEV-toolsSetup_4.1_5.iso
        oVirt-toolsSetup-4.0-1.fc24.iso
        oVirt-toolsSetup-4.1-3.fc24.iso
        oVirt-toolsSetup-4.2-4.fc25.iso
        rhev-tools-setup.iso
        virtio-win-1.9.0.iso
      ).each { |iso| isos[iso] = iso }

      expect(ae_service.object['values']).to eq(isos)
    end
  end

  context 'without ISO domain' do
    let!(:provider) { FactoryGirl.create(:ems_redhat, :with_clusters) }
    let(:iso_domain) { nil }

    it 'should list informative message' do
      described_class.new(ae_service).main

      items = { nil => '-- no ISO datastore for provider --' }
      expect(ae_service.object['values']).to eq(items)
    end
  end
end
