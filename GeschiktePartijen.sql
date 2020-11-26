DECLARE @DaysBack INT = -1;

SELECT 
	Sub.*
FROM
(
	SELECT 
		DATEADD(HOUR, 2, HLM.HIS_TIMESTAMP)  Verplaatst,
		HLM.HIS_ACTION  Actie,
		LU.LogisticUnitID,
		ISNULL(LU.LastConfirmedLocationID, C1.LastConfirmedLocationID)  Locatie,
		SUBSTRING(ISNULL(LU.LastConfirmedLocationID, C1.LastConfirmedLocationID), 7, 2) Pad,
		LU.LastConfirmedContainerID ContainerID,
		ArticleID ArtikelNummer,
		LUE.LotID,
		Quantity Aantal


	FROM wcs.LogisticUnits LU WITH (NOLOCK)
	JOIN dbo.LogisticUnitExtensions LUE WITH (NOLOCK) ON LU.LogisticUnitID = LUE.LogisticUnitID
	LEFT JOIN wcs.Containers C1 WITH (NOLOCK) ON LU.LastConfirmedContainerID = C1.ContainerID
	LEFT JOIN um.users U WITH (NOLOCK) ON LU.ModifiedByUserID = U.Id
	INNER JOIN (SELECT LUM.*,
				ROW_NUMBER() 
				  OVER ( 
					PARTITION BY LogisticUnitID 
					ORDER BY HIS_TIMESTAMP DESC ) AS seqnum 
				 FROM Hist.dbo_LogisticUnitMovements LUM
				 WHERE HIS_TIMESTAMP > DATEADD(DAY, @DaysBack, GETUTCDATE())) HLM 
			 ON LU.LogisticUnitID = HLM.LogisticUnitID
				AND seqnum = 1 

	WHERE Identifiable = 0 and Quantity > 0
	AND LEFT(ISNULL(LU.LastConfirmedLocationID, C1.LastConfirmedLocationID) , 4) = 'STWO'

	AND HLM.HIS_ACTION = 'UPDATE'

) Sub

INNER JOIN (SELECT LotID, MAX(Quantity) Quantity
			FROM WCS.LogisticUnits LUU WITH (NOLOCK)
			JOIN dbo.LogisticUnitExtensions LUE WITH (NOLOCK)
			ON LUU.LogisticUnitID = LUE.LogisticUnitID
			GROUP BY LUE.LotID
			) LUAGG ON Sub.Aantal = LUAGG.Quantity AND Sub.LotID = LUAGG.LotID

WHERE ISNUMERIC(PAD) = 1
