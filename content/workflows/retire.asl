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
      "Parameters": {
        "RemoveFromProvider": true,
        "RemoveFromProviderStorage": true,
        "RemoveFromInventory": true
      },
      "Next": "PostRetire"
    },
    "PostRetire": {
      "Type": "Pass",
      "End": true
    }
  }
}
