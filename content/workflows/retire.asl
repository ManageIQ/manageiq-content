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
      "Parameters": {
        "RemoveFromProvider": true,
        "RemovalType": "remove_from_disk",
        "DeleteFromVmdb": true
      },
      "Next": "PostRetire"
    },
    "PostRetire": {
      "Type": "Pass",
      "End": true
    }
  }
}
