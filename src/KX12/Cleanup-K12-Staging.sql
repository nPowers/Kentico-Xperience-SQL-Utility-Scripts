
alter table dbo.Staging_Synchronization nocheck constraint all
alter table dbo.Staging_Task nocheck constraint all
alter table dbo.Staging_TaskUser nocheck constraint all
alter table dbo.Staging_TaskGroup nocheck constraint all
alter table dbo.Staging_TaskGroupTask nocheck constraint all
alter table dbo.Staging_TaskGroupUser nocheck constraint all

declare @breakbyerror int = 0, @deleted_rows int = 1;
print convert(varchar(25), getdate(), 121) + ': Start deleting tasks for records in staging'
set @deleted_rows = 1;
while (@deleted_rows > 0 and @breakbyerror = 0)
begin
       begin try
       begin tran
       DELETE FROM [dbo].[Staging_Synchronization] WHERE SynchronizationTaskID IN (SELECT TaskID FROM [dbo].[Staging_Task] where TaskTitle like '%OTT_R%')
       set @deleted_rows = @@rowcount;
       print convert(varchar(25), getdate(), 121) + ':   ' + cast(@deleted_rows as varchar(max)) + ' records deleted'
       print convert(varchar(25), getdate(), 121) + ':   Commit transaction'
       commit tran
       end try
       begin catch
       select  ERROR_NUMBER() AS ErrorNumber
                     ,ERROR_SEVERITY() AS ErrorSeverity
                     ,ERROR_STATE() AS ErrorState
                     ,ERROR_PROCEDURE() AS ErrorProcedure
                     ,ERROR_LINE() AS ErrorLine
                     ,ERROR_MESSAGE() AS ErrorMessage;
        
       print convert(varchar(25), getdate(), 121) + ':   Rollback transaction'
       rollback tran
       set @breakbyerror = 1
       end catch
end
 
print convert(varchar(25), getdate(), 121) + ': Start deleting tasks for  records in staging'
set @deleted_rows = 1;
while (@deleted_rows > 0 and @breakbyerror = 0)
begin
       begin try
       begin tran
       DELETE FROM [dbo].[Staging_Task] --where TaskTitle like '%OTT_R%'
       set @deleted_rows = @@rowcount;
       print convert(varchar(25), getdate(), 121) + ':   ' + cast(@deleted_rows as varchar(max)) + ' records deleted'
       print convert(varchar(25), getdate(), 121) + ':   Commit transaction'
       commit tran
       end try
       begin catch
       select  ERROR_NUMBER() AS ErrorNumber
                     ,ERROR_SEVERITY() AS ErrorSeverity
                     ,ERROR_STATE() AS ErrorState
                     ,ERROR_PROCEDURE() AS ErrorProcedure
                     ,ERROR_LINE() AS ErrorLine
                     ,ERROR_MESSAGE() AS ErrorMessage;
        
       print convert(varchar(25), getdate(), 121) + ':   Rollback transaction'
       rollback tran
       set @breakbyerror = 1
       end catch

	   begin try
       begin tran
       DELETE FROM staging_TaskGroupTask --where TaskTitle like '%OTT_R%'
       set @deleted_rows = @@rowcount;
       print convert(varchar(25), getdate(), 121) + ':   ' + cast(@deleted_rows as varchar(max)) + ' records deleted'
       print convert(varchar(25), getdate(), 121) + ':   Commit transaction'
       commit tran
       end try
       begin catch
       select  ERROR_NUMBER() AS ErrorNumber
                     ,ERROR_SEVERITY() AS ErrorSeverity
                     ,ERROR_STATE() AS ErrorState
                     ,ERROR_PROCEDURE() AS ErrorProcedure
                     ,ERROR_LINE() AS ErrorLine
                     ,ERROR_MESSAGE() AS ErrorMessage;
        
       print convert(varchar(25), getdate(), 121) + ':   Rollback transaction'
       rollback tran
       set @breakbyerror = 1
       end catch

	   begin try
       begin tran
       DELETE FROM Staging_TaskUser --where TaskTitle like '%OTT_R%'
       set @deleted_rows = @@rowcount;
       print convert(varchar(25), getdate(), 121) + ':   ' + cast(@deleted_rows as varchar(max)) + ' records deleted'
       print convert(varchar(25), getdate(), 121) + ':   Commit transaction'
       commit tran
       end try
       begin catch
       select  ERROR_NUMBER() AS ErrorNumber
                     ,ERROR_SEVERITY() AS ErrorSeverity
                     ,ERROR_STATE() AS ErrorState
                     ,ERROR_PROCEDURE() AS ErrorProcedure
                     ,ERROR_LINE() AS ErrorLine
                     ,ERROR_MESSAGE() AS ErrorMessage;
        
       print convert(varchar(25), getdate(), 121) + ':   Rollback transaction'
       rollback tran
       set @breakbyerror = 1
       end catch

	   begin try
       begin tran
       DELETE FROM Staging_TaskGroupUser --where TaskTitle like '%OTT_R%'
       set @deleted_rows = @@rowcount;
       print convert(varchar(25), getdate(), 121) + ':   ' + cast(@deleted_rows as varchar(max)) + ' records deleted'
       print convert(varchar(25), getdate(), 121) + ':   Commit transaction'
       commit tran
       end try
       begin catch
       select  ERROR_NUMBER() AS ErrorNumber
                     ,ERROR_SEVERITY() AS ErrorSeverity
                     ,ERROR_STATE() AS ErrorState
                     ,ERROR_PROCEDURE() AS ErrorProcedure
                     ,ERROR_LINE() AS ErrorLine
                     ,ERROR_MESSAGE() AS ErrorMessage;
        
       print convert(varchar(25), getdate(), 121) + ':   Rollback transaction'
       rollback tran
       set @breakbyerror = 1
       end catch
end
alter table dbo.Staging_Synchronization check constraint all 
alter table dbo.Staging_Task check constraint all
alter table dbo.Staging_TaskUser check constraint all
 alter table dbo.Staging_TaskGroup check constraint all
  alter table dbo.staging_TaskGroupTask check constraint all
  alter table dbo.Staging_TaskGroupUser check constraint all