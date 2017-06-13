require_domain_file

describe ManageIQ::Automate::Container::Openshift::Operations::AvailableProjects do
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
  let(:container_template) { FactoryGirl.create(:container_template, :name => 'my-template', :ems_id => ems.id) }
  let(:ems) { FactoryGirl.create(:ems_openshift) }

  shared_examples_for "#having only default value" do
    let(:default_desc_blank) { "<none>" }

    it "provides only default value to the project list" do
      described_class.new(ae_service).main

      expect(ae_service["values"]).to eq(nil => default_desc_blank)
      expect(ae_service["default_value"]).to be_nil
    end
  end

  shared_examples_for "#having the only project" do
    let(:project) { FactoryGirl.create(:container_project, :name => 'my-project', :ems_id => ems.id) }

    it "finds the only project and set it as the only item in the list" do
      project
      described_class.new(ae_service).main

      expect(ae_service["values"]).to include(project.name => project.name)
      expect(ae_service["default_value"]).to eq(project.name)
    end
  end

  shared_examples_for "#having all projects" do
    let(:default_desc) { "<select>" }
    let(:project1) { FactoryGirl.create(:container_project, :name => 'my-project1', :ems_id => ems.id) }
    let(:project2) { FactoryGirl.create(:container_project, :name => 'my-project2', :ems_id => ems.id) }

    it "finds all of the projects and populates the list" do
      project1
      project2
      described_class.new(ae_service).main

      expect(ae_service["values"]).to include(
        nil           => default_desc,
        project1.name => project1.name,
        project2.name => project2.name
      )
      expect(ae_service["default_value"]).to be_nil
    end
  end

  context "workspace has no service template" do
    let(:root_hash) { {} }

    it_behaves_like "#having only default value"
  end

  context "workspace has service template other than container" do
    let(:service_template) { FactoryGirl.create(:service_template) }

    it_behaves_like "#having only default value"
  end

  context "workspace has container template service template" do
    let(:service_template) do
      FactoryGirl.create(:service_template_container_template).tap do |service_template|
        allow(ServiceTemplate).to receive(:find).with(service_template.id).and_return(service_template)
        allow(service_template).to receive(:container_template).and_return(container_template)
      end
    end

    context "with all projects" do
      it_behaves_like "#having all projects"
    end

    context "with one project" do
      it_behaves_like "#having the only project"
    end
  end
end
