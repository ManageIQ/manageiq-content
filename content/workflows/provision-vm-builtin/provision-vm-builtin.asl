{
  "Comment": "Basic VM Provisioning",
  "StartAt": "PreProvision",
  "States": {
    "PreProvision": {
      "Type": "Pass",
      "Next": "Provision"
    },
    "Provision": {
      "Type": "Task",
      "Resource": "builtin://provision_execute",
      "Next": "PostProvision"
    },
    "PostProvision": {
      "Type": "Pass",
      "End": true
    }
  }
}
