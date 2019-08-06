#! /usr/bin/python

from __future__ import (absolute_import, division, print_function)
import os

__metaclass__ = type

ANSIBLE_METADATA = {'metadata_version': '1.1',
                    'status': ['preview'],
                    'supported_by': 'community'}

DEFAULT_RETRY_INTERVAL = 60


DOCUMENTATION = '''
module: manageiq_automate
'''
import json
import operator
from ansible.module_utils.basic import AnsibleModule
from ansible.module_utils.urls import fetch_url


class ManageIQAutomate(object):
    """
        Object to execute automate workspace management operations in manageiq.
    """

    def __init__(self, module, workspace):
        self._target = workspace
        self._module = module
        self._api_url = self._module.params['manageiq_connection']['url'] + '/api'
        self._auth = self._build_auth()


    def _build_auth(self):
        self._headers = {'Content-Type': 'application/json; charset=utf-8'}
        # Force CERT validation to work with fetch_url
        self._module.params['validate_certs'] = self._module.params['manageiq_connection']['manageiq_validate_certs']
        for cert in ('force_basic_auth', 'client_cert', 'client_key'):
            self._module.params[cert] = self._module.params['manageiq_connection'][cert]
        if self._module.params['manageiq_connection'].get('token'):
            self._headers["X-Auth-Token"] = self._module.params['manageiq_connection']['token']
        else:
            self._module.params['url_username'] = self._module.params['manageiq_connection']['username']
            self._module.params['url_password'] = self._module.params['manageiq_connection']['password']



    def url(self):
        """
            The url to connect to the workspace
        """
        url_str = self._module.params['manageiq_connection']['automate_workspace']
        if url_str is None:
            self._module.fail_json(msg='Required parameter \'automate_workspace\' is not specified')
        return self._api_url + '/' + url_str


    def href_slug_url(self, value):
        """
            The url to connect to the vmdb
        """
        base_url = value.split('::')[1]
        return self._api_url + '/' + base_url


    def get(self, alt_url=None):
        """
            Get any attribute, object from the REST API
        """
        if alt_url:
            url = alt_url
        else:
            url = self.url()

        result, _info = fetch_url(self._module, url, None, self._headers, 'get')
        if result is None:
            self._module.fail_json(msg=_info['msg'])
        return json.loads(result.read())


    def set(self, data):
        """
            Set any attribute, object from the REST API
        """
        post_data = json.dumps(dict(action='edit', resource=data))
        result, _info = fetch_url(self._module, self.url(), post_data, self._headers, 'post')
        return  json.loads(result.read())


    def encrypt(self, data):
        """
            Set any attribute, object from the REST API
        """
        post_data = json.dumps(dict(action='encrypt', resource=data))
        result, _info = fetch_url(self._module, self.url(), post_data, self._headers, 'post')
        return  json.loads(result.read())


    def decrypt(self, data):
        """
            Decrypt any attribute, object from the REST API
        """
        post_data = json.dumps(dict(action='decrypt', resource=data))
        result, _info = fetch_url(self._module, self.url(), post_data, self._headers, 'post')
        return  json.loads(result.read())


    def exists(self, path):
        """
            Validate all passed objects before attempting to set or get values from them
        """
        list_path = path.split("|")
        try:
            return bool(reduce(operator.getitem, list_path, self._target))
        except KeyError as error:
            return False


    def auto_commit(self):
        """ ManageIQAutomate

        Returns:
            Boolean auto_commit on or off
        """
        return bool(self._target['workspace']['options'].get('auto_commit'))


class Workspace(ManageIQAutomate):
    """
        Object to modify and get the Workspace
    """

    def current(self):
        current_path = '/' + self._target['workspace']['current']['namespace'] + '/'
        self._target['workspace']['current']['class'] + '/'
        self._target['workspace']['current']['instance']
        return current_path


    def set_or_commit(self):
        """
            Commit the workspace or return the current version
        """
        if self.auto_commit():
            return self.commit_workspace()
        return dict(changed=True, workspace=self._target['workspace'])


    def get_real_object_name(self, dict_options):
        if dict_options['object'] == 'current':
            return self.current()
        return dict_options['object']


    def object_exists(self, dict_options):
        """
            Check if the specific object exists
        """

        search_path = "workspace|input|objects|" + self.get_real_object_name(dict_options)

        if self.exists(search_path):
            return dict(changed=False, value=True)
        return dict(changed=False, value=False)


    def attribute_exists(self, dict_options):
        """
            Check if the specific attribute exists
        """

        obj = self.get_real_object_name(dict_options)
        attribute = dict_options['attribute']
        path = "workspace|input|objects"
        search_path = "|".join([path, obj, attribute])
        if self.exists(search_path):
            return dict(changed=False, value=True)
        return dict(changed=False, value=False)


    def state_var_exists(self, dict_options):
        """
            Check if the specific state_var exists
        """

        attribute = dict_options['attribute']
        path = "workspace|input|state_vars"
        search_path = "|".join([path, attribute])
        if self.exists(search_path):
            return dict(changed=False, value=True)
        return dict(changed=False, value=False)


    def method_parameter_exists(self, dict_options):
        """
            Check if the specific method_parameter exists
        """

        parameter = dict_options['parameter']
        path = "workspace|input|method_parameters"
        search_path = "|".join([path, parameter])
        if self.exists(search_path):
            return dict(changed=False, value=True)
        return dict(changed=False, value=False)


    def get_decrypted_attribute(self, dict_options):
        decrypted_attribute = self.decrypt(dict_options)
        return dict(changed=False, value=decrypted_attribute)


    def get_decrypted_method_parameter(self, dict_options):
        decrypted_dict = dict(object='method_parameters', attribute=dict_options['attribute'])
        decrypted_attribute = self.decrypt(decrypted_dict)
        return dict(changed=False, value=decrypted_attribute)


    def get_attribute(self, dict_options):
        """
            Get the passed in attribute from the Workspace
        """

        if self.attribute_exists(dict_options)['value']:
            return_value = self._target['workspace']['input']['objects'][dict_options['object']][dict_options['attribute']]

            return dict(changed=False, value=return_value)
        else:
            self._module.fail_json(msg='Object %s Attribute %s does not exist' % (dict_options['object'], dict_options['attribute']))


    def get_state_var(self, dict_options):
        """
            Get the passed in state_var from the Workspace
        """
        return_value = None

        if self.state_var_exists(dict_options)['value']:
            return_value = self._target['workspace']['input']['state_vars'][dict_options['attribute']]

            return dict(changed=False, value=return_value)
        else:
            self._module.fail_json(msg='State Var %s does not exist' % dict_options['attribute'])


    def get_method_parameter(self, dict_options):
        """
            Get the passed in method_parameter from the Workspace
        """
        return_value = None

        if self.method_parameter_exists(dict_options)['value']:
            return_value = self._target['workspace']['input']['method_parameters'][dict_options['parameter']]

            return dict(changed=False, value=return_value)
        else:
            self._module.fail_json(msg='Method Parameter %s does not exist' % dict_options['parameter'])


    def get_object_names(self):
        """
            Get a list of all current object names
        """

        return_value = self._target['workspace']['input']['objects'].keys()
        return dict(changed=False, value=return_value)


    def get_method_parameters(self):
        """
            Get a list of all current method_paramters
        """

        return_value = self._target['workspace']['input']['method_parameters']
        return dict(changed=False, value=return_value)


    def get_state_var_names(self):
        """
            Get a list of all current state_var names
        """

        return_value = self._target['workspace']['input']['state_vars'].keys()
        return dict(changed=False, value=return_value)


    def get_object_attribute_names(self, dict_options):
        """
            Get a list of all object_attribute names
        """

        if self.object_exists(dict_options):
            return_value = self._target['workspace']['input']['objects'][dict_options['object']].keys()
            return dict(changed=False, value=return_value)
        else:
            self._module.fail_json(msg='Object %s does not exist' % dict_options['object'])


    def get_vmdb_object(self, dict_options):
        """
            Get a vmdb object via an href_slug passed in on an attribute
        """
        result = self.get_attribute(dict_options)
        attribute = dict_options['attribute']
        obj = dict_options['object']
        if self.object_exists(dict_options):
            vmdb_object = self.get(self.href_slug_url(result['value']))
            return dict(changed=False, value=vmdb_object)
        else:
            self._module.fail_json(msg='Attribute %s does not exist for Object %s' % (attribute, obj))


    def set_state_var(self, dict_options):
        """
            Set the state_var called with the passed in value
        """

        new_attribute = dict_options['attribute']
        new_value = dict_options['value']
        self._target['workspace']['input']['state_vars'][new_attribute] = new_value
        self._target['workspace']['output']['state_vars'][new_attribute] = new_value
        return self.set_or_commit()


    def set_retry(self, dict_options):
        """
            Set Retry
        """
        retry_interval = dict_options.get('interval') or DEFAULT_RETRY_INTERVAL

        attributes = dict()
        attributes['object'] = 'root'
        attributes['attributes'] = dict(ae_result='retry', ae_retry_interval=retry_interval)

        self.set_attributes(attributes)
        return self.set_or_commit()


    def set_encrypted_attribute(self, dict_options):
        """
            Set encrypted attribute
        """
        encrypted_attribute = self.encrypt(dict_options)
        return dict(changed=True, value=encrypted_attribute)


    def set_attribute(self, dict_options):
        """
            Set the attribute called on the object with the passed in value
        """

        new_attribute = dict_options['attribute']
        new_value = dict_options['value']
        obj = self.get_real_object_name(dict_options)
        if self.object_exists(dict_options):
            self._target['workspace']['input']['objects'][obj][new_attribute] = new_value
            new_dict = {obj:{new_attribute: new_value}}
            self._target['workspace']['output']['objects'] = new_dict
            return self.set_or_commit()
        else:
            msg = 'Failed to set the attribute %s with value %s for %s' % (new_attribute, new_value, obj)
            self._module.fail_json(msg=msg, changed=False)


    def set_attributes(self, dict_options):
        """
            Set the attributes called on the object with the passed in values
        """
        new_attributes = dict_options['attributes']

        obj = dict_options['object']
        if self.object_exists(dict_options):
            for new_attribute, new_value in new_attributes.items():
                self._target['workspace']['input']['objects'][obj][new_attribute] = new_value
                if self._target['workspace']['output']['objects'].get(obj) is None:
                    self._target['workspace']['output']['objects'][obj] = dict()
                self._target['workspace']['output']['objects'][obj][new_attribute] = new_value
            return self.set_or_commit()
        else:
            msg = 'Failed to set the attributes %s for %s' % (new_attributes, obj)
            self._module.fail_json(msg=msg, changed=False)


    def commit_workspace(self):
        """
            Commit the workspace and re apply the auto_commit options
        """
        auto_commit_dict = self._target['workspace'].get('options')
        workspace = self.set(self._target['workspace']['output'])
        if 'options' not in workspace.keys():
            workspace['options'] = auto_commit_dict
        return dict(changed=True, workspace=workspace)


    def initialize_workspace(self, dict_options):
        """
            Initialize the Workspace with auto_commit set to true or false
        """

        workspace = self.get()
        workspace['options'] = dict(auto_commit=(dict_options.get('auto_commit') or False))
        workspace['output'] = dict(objects=dict(), state_vars=dict())

        return dict(changed=False, workspace=workspace)


def manageiq_argument_spec():
    return dict(
        url=dict(default=os.environ.get('MIQ_URL', None)),
        username=dict(default=os.environ.get('MIQ_USERNAME', None)),
        password=dict(default=os.environ.get('MIQ_PASSWORD', None), no_log=True),
        token=dict(default=os.environ.get('MIQ_TOKEN', None), no_log=True),
        automate_workspace=dict(default=None, type='str', no_log=True),
        group=dict(default=None, type='str'),
        X_MIQ_Group=dict(default=None, type='str'),
        manageiq_validate_certs=dict(required=False, type='bool', default=True),
        force_basic_auth=dict(required=False, type='bool', default='no'),
        client_cert=dict(required=False, type='path', default=None),
        client_key=dict(required=False, type='path', default=None),
    )


def main():
    """
        The entry point to the ManageIQ Automate module
    """
    module = AnsibleModule(
            argument_spec=dict(
                manageiq_connection=dict(required=True, type='dict',
                                         options=manageiq_argument_spec()),
                initialize_workspace=dict(required=False, type='dict'),
                commit_workspace=dict(type='bool', default=False),
                set_attribute=dict(required=False, type='dict'),
                set_attributes=dict(required=False, type='dict'),
                object_exists=dict(required=False, type='str'),
                attribute_exists=dict(required=False, type='dict'),
                state_var_exists=dict(required=False, type='dict'),
                method_parameter_exists=dict(required=False, type='dict'),
                commit_attribute=dict(required=False, type='dict'),
                commit_attributes=dict(required=False, type='dict'),
                commit_state_var=dict(required=False, type='dict'),
                get_attribute=dict(required=False, type='dict'),
                get_state_var=dict(required=False, type='dict'),
                get_method_parameter=dict(required=False, type='dict'),
                set_retry=dict(required=False, type='dict'),
                set_state_var=dict(required=False, type='dict'),
                set_encrypted_attribute=dict(required=False, type='dict'),
                get_vmdb_object=dict(required=False, type='dict'),
                get_decrypted_attribute=dict(required=False, type='dict'),
                get_decrypted_method_parameter=dict(required=False, type='dict'),
                get_object_names=dict(required=False, type='bool'),
                get_state_var_names=dict(required=False, type='bool'),
                get_method_parameters=dict(required=False, type='bool'),
                get_object_attribute_names=dict(required=False, type='dict'),
                workspace=dict(required=False, type='dict')
                ),
            )

    argument_opts = {
        'initialize_workspace':module.params['initialize_workspace'],
        'commit_workspace':module.params['commit_workspace'],
        'get_attribute':module.params['get_attribute'],
        'get_method_parameter':module.params['get_method_parameter'],
        'get_state_var':module.params['get_state_var'],
        'get_object_attribute_names':module.params['get_object_attribute_names'],
        'get_vmdb_object':module.params['get_vmdb_object'],
        'get_decrypted_attribute':module.params['get_decrypted_attribute'],
        'get_decrypted_method_parameter':module.params['get_decrypted_method_parameter'],
        'object_exists':module.params['object_exists'],
        'method_parameter_exists':module.params['method_parameter_exists'],
        'attribute_exists':module.params['attribute_exists'],
        'state_var_exists':module.params['state_var_exists'],
        'set_attribute':module.params['set_attribute'],
        'set_attributes':module.params['set_attributes'],
        'set_encrypted_attribute':module.params['set_encrypted_attribute'],
        'set_retry':module.params['set_retry'],
        'set_state_var':module.params['set_state_var']
        }

    boolean_opts = {
        'get_object_names':module.params['get_object_names'],
        'get_method_parameters':module.params['get_method_parameters'],
        'get_state_var_names':module.params['get_state_var_names']
        }

    workspace = Workspace(module, module.params['workspace'])

    for key, value in boolean_opts.items():
        if value:
            result = getattr(workspace, key)()
            module.exit_json(**result)
    for key, value in argument_opts.items():
        if value:
            result = getattr(workspace, key)(value)
            module.exit_json(**result)


    module.fail_json(msg="No workspace found")


if __name__ == "__main__":
    main()
