CREATE NONCLUSTERED INDEX [IX_ActivityByContactAndCreated]
ON [dbo].[OM_Activity] ([ActivityContactID])
INCLUDE ([ActivityCreated])