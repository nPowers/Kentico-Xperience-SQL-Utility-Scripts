UPDATE CMS_AttachmentHistory SET AttachmentBinary = NULL WHERE AttachmentLastModified < DATEADD(month, -6, GetDate())

