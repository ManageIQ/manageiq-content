#! /usr/bin/python

from __future__ import (absolute_import, division, print_function)
import os

__metaclass__ = type

ANSIBLE_METADATA = {'metadata_version': '1.1',
                    'status': ['preview'],
                    'supported_by': 'community'}


DOCUMENTATION = '''
module: manageiq_vmdb
'''
import json
import re
from ansible.module_utils.basic import AnsibleModule
from ansible.module_utils.urls import fetch_url
from ansible.module_utils.six.moves.urllib.parse import urlparse

class ManageIQVmdb(object):
    """
        Object to execute VMDB management operations in manageiq.
    """

    def __init__(self, module):
        self._module = module
        self._debug = bool(self._module._verbosity >= 3)
        self._api_url = self._module.params['manageiq_connection']['url']
        self._vmdb = self._module.params.get('vmdb') or self._module.params.get('href')
        self._href = None
        self._error = None
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




    @property
    def url(self):
        """
            The url to connect to the VMDB Object
        """
        return self.build_url()


    def build_url(self):
        """
            Using any type of href input, build out the correct url
        """

        url_actual = urlparse(self._href)
        if re.search('api', url_actual.path):
            return self._api_url + url_actual.path
        return self._api_url + '/api/' + url_actual.path


    def build_result(self, method, data=None):
        """
            Make the REST call and return the result to the caller
        """
        result, info = fetch_url(self._module, self.url, data, self._headers, method)
        try:
            vmdb = json.loads(result.read())
            if self._debug:
                vmdb['debug'] = info
            return vmdb
        except AttributeError:
            self._module.fail_json(msg=info)
        return json.loads(result.read())


    def get(self):
        """
            Get any attribute, object from the REST API
        """
        return self.build_result('get')


    def set(self, post_dict):
        """
            Set any attribute, object from the REST API
        """
        post_data = json.dumps(dict(action=post_dict['action'], resource=post_dict['resource']))
        return self.build_result('post', post_data)


    def parse(self, item):
        """
            Read what is passed in and set the _href instance variable
        """
        if isinstance(item, dict):
            self._href = self._vmdb['href']
        elif isinstance(item, str):
            slug = item.split("::")
            if len(slug) == 2:
                self._href = slug[1]
                return
            self._href = item


    def exists(self, path):
        """
            Validate all passed objects before attempting to set or get values from them
        """
        result = self.get()
        actions = [d['name'] for d in result['actions']]
        return bool(path in actions)


class Vmdb(ManageIQVmdb):
    """
        Object to modify and get the Vmdb Object
    """

    def get_object(self):
        """
            Return the VMDB Object
        """
        self.parse(self._vmdb)
        return dict(self.get())


    def action(self):
        """
            Call an action if it exists
        """
        self.parse(self._vmdb)
        data = self._module.params['data']
        action_string = self._module.params.get('action')

        if self.exists(action_string):
            result = self.set(dict(action=action_string, resource=data))
            if result or result['success']:
                return dict(changed=True, value=result)
            return self._module.fail_json(msg=result['message'])
        return self._module.fail_json(msg="Action not found")


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
        client_key=dict(required=False, type='path', default=None)
    )


def main():
    """
        The entry point to the ManageIQ Vmdb module
    """
    module = AnsibleModule(
            argument_spec=dict(
                manageiq_connection=dict(required=True, type='dict',
                                         options=manageiq_argument_spec()),
                vmdb=dict(required=False, type='dict'),
                action=dict(required=False, type='str'),
                href=dict(required=False, type='str'),
                data=dict(required=False, type='dict')
                ),
            required_one_of=[['vmdb', 'href']]
            )


    vmdb = Vmdb(module)

    if module.params.get('action'):
        result = vmdb.action()
        module.exit_json(**result)
    else:
        result = vmdb.get_object()
        module.exit_json(**result)

    module.fail_json(msg="No VMDB object found")


if __name__ == "__main__":
    main()
