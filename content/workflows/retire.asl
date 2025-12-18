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
      "Next": "EmailOwner"
    },
    "EmailOwner": {
      "Type": "Task",
      "Resource": "manageiq://email",
      "Parameters": {
        "To.$": "$$._object_details.owner.email",
        "Subject": "Your instance has been retired"
      },
      "Catch": [
        {
          "ErrorEquals": ["States.TaskFailed"],
          "Next": "PostRetire"
        }
      ],
      "Next": "PostRetire"
    },
    "PostRetire": {
      "Type": "Pass",
      "End": true
    }
  }
}
