{
  "Comment": "Send an email",
  "StartAt": "SendEmail",
  "States": {
    "SendEmail": {
      "Type": "Task",
      "Resource": "manageiq://email",
      "Parameters": {
        "To.$": "$.to",
        "From.$": "$.from",
        "Subject.$": "$.subject",
        "Cc.$": "$.cc",
        "Bcc.$": "$.bcc",
        "Body.$": "$.body",
        "Attachment.$": "$.attachment"
      },
      "End": true
    }
  }
}
