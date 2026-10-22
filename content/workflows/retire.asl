{
  "Comment": "Basic Retirement",
  "StartAt": "PreRetire",
  "States": {
    "PreRetire": {
      "Type": "Pass",
      "Next": "Retire"
    },
    "Retire": {
      "Type": "Task",
      "Resource": "manageiq://retire_execute",
      "TimeoutSeconds": 3600,
      "Next": "PostRetire"
    },
    "PostRetire": {
      "Type": "Pass",
      "End": true
    }
  }
}
