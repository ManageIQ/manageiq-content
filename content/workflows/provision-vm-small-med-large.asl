{
  "Comment": "Provision VM with choice for small medium large",
  "StartAt": "DetermineSize",
  "States": {
    "DetermineSize": {
      "Comment": "Determine dialog value",
      "Type": "Choice",
      "Choices": [
        {
          "Variable": "$.size",
          "StringEquals": "small",
          "Next": "SmallSizeState"
        },
        {
          "Variable": "$.size",
          "StringEquals": "medium",
          "Next": "MediumSizeState"
        },
        {
          "Variable": "$.size",
          "StringEquals": "large",
          "Next": "LargeSizeState"
        }
      ],
      "Default": "SmallSizeState"
    },
    "SmallSizeState": {
      "Type": "Pass",
      "Next": "SmallSetMemory"
    },
    "SmallSetMemory": {
      "Comment": "set vm_memory=2GB for small",
      "Type": "Pass",
      "ResultPath": "$.vm_memory",
      "Result":     "2048",
      "Next": "SmallSetCpus"
    },
    "SmallSetCpus": {
      "Comment": "1 cpu for small",
      "Type": "Pass",
      "ResultPath": "$.number_of_sockets",
      "Result":     "1",
      "Next": "Provision"
    },
    "MediumSizeState": {
      "Type": "Pass",
      "Next": "MediumSetMemory"
    },
    "MediumSetMemory": {
      "Comment": "set vm_memory=4GB for medium",
      "Type": "Pass",
      "ResultPath": "$.vm_memory",
      "Result":     "4096",
      "Next": "MediumSetCpus"
    },
    "MediumSetCpus": {
      "Comment": "2 cpus for medium",
      "Type": "Pass",
      "ResultPath": "$.number_of_sockets",
      "Result":     "2",
      "Next": "Provision"
    },
    "LargeSizeState": {
      "Type": "Pass",
      "Next": "LargeSetMemory"
    },
    "LargeSetMemory": {
      "Comment": "set vm_memory=8GB for large",
      "Type": "Pass",
      "ResultPath": "$.vm_memory",
      "Result":     "8192",
      "Next": "LargeSetCpus"
    },
    "LargeSetCpus": {
      "Comment": "4 cpus for large",
      "Type": "Pass",
      "ResultPath": "$.number_of_sockets",
      "Result":     "4",
      "Next": "Provision"
    },
    "Provision": {
      "Type": "Task",
      "Resource": "manageiq://provision_execute",
      "Next": "SendEmail"
    },
    "SendEmail": {
      "Type": "Task",
      "Resource": "manageiq://email",
      "Parameters": {
        "To": "user@example.com",
        "Title": "Your provisioning has completed",
        "Body": "Your provisioning request has completed"
      },
      "Next": "Finished"
    },
    "Finished": {
      "Type": "Succeed"
    }
  }
}
