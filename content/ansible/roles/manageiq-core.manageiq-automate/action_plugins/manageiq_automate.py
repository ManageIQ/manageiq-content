from __future__ import (absolute_import, division, print_function)
__metaclass__ = type
from ansible.plugins.action import ActionBase
from ansible.utils.vars import merge_hash

MANAGEIQ_MODULE_VARS = ('username',
                        'password',
                        'url',
                        'token',
                        'group',
                        'automate_workspace',
                        'X_MIQ_Group',
                        'manageiq_validate_certs',
                        'force_basic_auth',
                        'client_cert',
                        'client_key')



class ActionModule(ActionBase):

    def manageiq_extra_vars(self, module_vars, task_vars):
        if 'manageiq_connection' in task_vars.keys():
            module_vars['manageiq_connection'] = task_vars['manageiq_connection']
        if 'manageiq_validate_certs' in task_vars.keys():
            module_vars['manageiq_connection']['manageiq_validate_certs'] = task_vars.get('manageiq_validate_certs')
        if 'manageiq' not in task_vars.keys():
            return module_vars


        if 'manageiq_connection' not in module_vars.keys() or module_vars['manageiq_connection'] is None:
            module_vars['manageiq_connection'] = dict()

        for k in MANAGEIQ_MODULE_VARS:
            if k not in module_vars['manageiq_connection'].keys():
                try:
                    module_vars['manageiq_connection'][k] = task_vars['manageiq'][k]
                except KeyError:
                    pass


        return module_vars


    def run(self, tmp=None, task_vars=None):
        results = super(ActionModule, self).run(tmp, task_vars or dict())

        module_vars = self.manageiq_extra_vars(self._task.args.copy(), task_vars)

        results = merge_hash(
            results,
            self._execute_module(module_args=module_vars, task_vars=task_vars),
        )

        return results
