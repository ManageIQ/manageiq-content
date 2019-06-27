describe "DialogParser Automate Method" do
  include Spec::Support::ServiceTemplateHelper

  before(:each) do
    @root_stp = FactoryBot.create(:service_template_provision_task)
    @user = FactoryBot.create(:user_with_group)
  end

  def run_automate_method
    attrs = []
    attrs << "ServiceTemplateProvisionTask::service_template_provision_task=#{@root_stp.id}"

    MiqAeEngine.instantiate("/System/Request/Call_Instance_With_Message?" \
                            "namespace=Service/Provisioning/StateMachines&class=Methods" \
                            "&instance=DialogParser&" \
                            "#{attrs.join('&')}", @user)
  end

  def create_tags
    FactoryBot.create(:classification_department_with_tags)
    @array_name = "Array::dialog_tag_0_department"
    @dept_ids = Classification.find_by_description('Department').children.collect do |x|
      "Classification::#{x.id}"
    end.join(',')

    @dept_array = Classification.find_by_description('Department').children.collect(&:name)
  end

  def create_vms
    @vm_array_name = "Array::dialog_vm_array"
    @vm_id_array   = []
    @vm_name_array = []
    [FactoryBot.create(:vm), FactoryBot.create(:vm)].each do |vm|
      @vm_id_array << "Vm::#{vm.id}"
      @vm_name_array << vm.name
    end
  end

  def setup_and_run_method(dialog_hash)
    @root_stp.options = @root_stp.options.merge(:dialog => dialog_hash)
    @root_stp.save
    run_automate_method
    @root_stp.reload
  end

  def load_options
    YAML.load(@root_stp.get_option(:parsed_dialog_options))
  end

  def load_tags
    YAML.load(@root_stp.get_option(:parsed_dialog_tags))
  end

  context "parser" do
    it "with options tags and arrays" do
      array_key = "Array::dialog_str_array"
      array_value = %w(1 2 3)
      create_tags
      create_vms
      dialog_hash = {'dialog_option_1_numero' => 'one', 'dialog_option_2_numero' => 'two',
                     'dialog_option_3_numero' => 'three', 'dialog_option_0_numero' => 'zero',
                     'dialog_tag_0_location' => 'NYC', 'dialog_tag_1_location' => 'BOM',
                     'dialog_tag_2_location' => 'EWR', @array_name => @dept_ids,
                     array_key               => array_value.join(","),
                     @vm_array_name          => @vm_id_array.join(",")}

      parsed_dialog_options_hash = {1 => {:numero => "one"},
                                    2 => {:numero => "two"},
                                    3 => {:numero => "three"},
                                    0 => {:numero => "zero", :str_array => array_value,
                                          :dialog_str_array => array_value,
                                          :dialog_vm_array  => @vm_name_array,
                                          :vm_array         => @vm_name_array}}
      parsed_dialog_tags_hash = {0 => {:location => "NYC"},
                                 1 => {:location => "BOM"},
                                 2 => {:location => "EWR"}}

      setup_and_run_method(dialog_hash)
      pdo = load_options
      pdt = load_tags
      depts = pdt[0].delete(:department)
      expect(pdo).to eql(parsed_dialog_options_hash)
      expect(pdt).to eql(parsed_dialog_tags_hash)
      expect(depts).to match_array(@dept_array)
    end

    it "with password option" do
      dialog_hash = {'password::dialog_option_1_passwordtest' => "v2:{i7uvqmb1Dr6WAxCpakNE9w==}"}
      parsed_dialog_options_hash = {1 => {:"password::dialog_passwordtest" => "v2:{i7uvqmb1Dr6WAxCpakNE9w==}",
                                          :"password::passwordtest"        => "v2:{i7uvqmb1Dr6WAxCpakNE9w==}"}}
      setup_and_run_method(dialog_hash)
      pdo = load_options

      expect(pdo).to eql(parsed_dialog_options_hash)
    end

    it "with generic password" do
      dialog_hash = {'password::dialog_passwordtest' => "v2:{i7uvqmb1Dr6WAxCpakNE9w==}"}
      parsed_dialog_options_hash = {0 => {:"password::dialog_passwordtest" => "v2:{i7uvqmb1Dr6WAxCpakNE9w==}",
                                          :"password::passwordtest"        => "v2:{i7uvqmb1Dr6WAxCpakNE9w==}"}}
      setup_and_run_method(dialog_hash)
      pdo = load_options

      expect(pdo).to eql(parsed_dialog_options_hash)
    end

    it "with provisioing dialog password" do
      dialog_hash = {'password::dialog_root_password' => "v2:{i7uvqmb1Dr6WAxCpakNE9w==}"}
      parsed_dialog_options_hash = {0 => {:"password::dialog_root_password" => "v2:{i7uvqmb1Dr6WAxCpakNE9w==}",
                                          :"password::root_password"        => "v2:{i7uvqmb1Dr6WAxCpakNE9w==}",
                                          :root_password                    => "v2:{i7uvqmb1Dr6WAxCpakNE9w==}"}}
      setup_and_run_method(dialog_hash)
      pdo = load_options

      expect(pdo).to eql(parsed_dialog_options_hash)
    end

    it "with no dialogs set" do
      @root_stp.options = @root_stp.options.merge(:dialog => {})
      @root_stp.save
      expect { run_automate_method }.not_to raise_exception
    end

    it "with blank dialog set" do
      @root_stp.options = @root_stp.options.merge(:dialog => {:dialog_text_box => ""})
      @root_stp.save
      expect { run_automate_method }.not_to raise_exception
    end
  end
end
