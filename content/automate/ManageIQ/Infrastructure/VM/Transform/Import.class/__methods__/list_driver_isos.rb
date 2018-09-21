module ManageIQ
  module Automate
    module Infrastructure
      module VM
        module Transform
          module Import
            class ListDriverIsos
              def initialize(handle = $evm)
                @handle = handle
              end

              def main
                values_hash = {}
                values_hash[nil] = '-- select provider first --'

                provider_id = @handle.root['dialog_provider']
                if provider_id.present? && provider_id != '!'
                  provider = @handle.vmdb(:ext_management_system, provider_id)
                  unless provider.nil?
                    if provider.iso_datastore.nil?
                      values_hash[nil] = '-- no ISO datastore for provider --'
                    else
                      values_hash[nil] = '-- select image from list --'
                      provider.iso_datastore.iso_images.pluck(:name).grep(/tools.*setup|virtio-win.*.iso$/i).each do |iso|
                        values_hash[iso] = iso
                      end
                    end
                  end
                end
                list_values = {
                  'sort_by'   => :description,
                  'data_type' => :string,
                  'required'  => true,
                  'values'    => values_hash,
                  'visible'   => @handle.root['dialog_install_drivers']
                }
                list_values.each { |key, value| @handle.object[key] = value }
              end
            end
          end
        end
      end
    end
  end
end

ManageIQ::Automate::Infrastructure::VM::Transform::Import::ListDriverIsos.new.main
