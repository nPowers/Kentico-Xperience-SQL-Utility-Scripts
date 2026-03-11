/* KenticoClearVersionHistoryAndAttachmentHistory.v11.sql	*/
/* Goal: Clean up data from Pages Tree			*/
/* Description: Truncates all version history   */
/*  that can bloat a database. Be very careful	*/
/*  with this one, there is no coming back		*/
/* Intended Kentico Verison: 11.x               */
/* Author: Brian McKeiver (mcbeev@gmail.com)    */
/* Revision: 1.0                                */
/* Take a backup first! Don't be THAT guy!      */

delete from CMS_WebFarmServerTask
GO
TRUNCATE TABLE CMS_WebFarmServerTask
GO
delete from CMS_WebFarmServerMonitoring
GO

TRUNCATE TABLE CMS_WebFarmServerMonitoring
GO

TRUNCATE TABLE CMS_WebFarmServerLog
GO
delete from CMS_WebFarmServer
GO
TRUNCATE TABLE CMS_WebFarmServer
GO
delete from CMS_WebFarmTask
GO
TRUNCATE TABLE CMS_WebFarmTask
GO