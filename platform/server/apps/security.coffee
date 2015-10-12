# Apps
Apps.permit(['insert', 'update', 'remove']).ifHasRole('admin').apply()
Apps.permit(['insert', 'update', 'remove']).ifUserIdSet().apply()
