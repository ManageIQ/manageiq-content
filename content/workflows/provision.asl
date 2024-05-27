{
  "Comment": "Basic Provisioning",
  "StartAt": "PreProvision",
  "States": {
    "PreProvision": {
      "Type": "Pass",
      "Next": "Provision"
    },
    "Provision": {
      "Type": "Task",
      "Resource": "manageiq://provision_execute",
      "Next": "PostProvision"
    },
    "PostProvision": {
      "Type": "Pass",
      "End": true
    }
  }
}
