{
  "Comment": "Basic Reconfigure",
  "StartAt": "PreReconfigure",
  "States": {
    "PreReconfigure": {
      "Type": "Pass",
      "Next": "Reconfigure"
    },
    "Reconfigure": {
      "Type": "Task",
      "Resource": "manageiq://reconfigure_execute",
      "Next": "PostReconfigure"
    },
    "PostReconfigure": {
      "Type": "Pass",
      "End": true
    }
  }
}
