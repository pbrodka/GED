/*
The GED method website http://www.ii.pwr.wroc.pl/~brodka/ged.php

If you use this code please cite:
Bródka P., Saganowski S., Kazienko P.: GED: The Method for Group Evolution Discovery in Social Networks, Social Network Analysis and Mining, March 2013, Volume 3, Issue 1, pp 1-14, DOI:10.1007/s13278-012-0058-8
 
Full Open Access description of GED can be found at:
http://link.springer.com/article/10.1007%2Fs13278-012-0058-8
http://arxiv.org/abs/1207.4297

In case of any problems you can contact us
piotr.brodka@pwr.wroc.pl				http://www.ii.pwr.wroc.pl/~brodka/index_en.php
stanislaw.saganowski@pwr.wroc.pl 

--------------------------------------------------------------------------
How to run the GED Method-------------------------------------------------
--------------------------------------------------------------------------

1.	Split your social network into timeframes. To check how different timeframe  type and size affect the GED measure you can read Saganowski S., Bródka P., Kazienko P.: Influence of the Dynamic Social Network Timeframe Type and Size on the Group Evolution Discovery. ASONAM 2012, IEEE Computer Society, 2012, pp. 678-682. (http://arxiv.org/abs/1210.5167)
2.	For each timeframe calculate the communities (extract groups) using any group detection method. The GED method was tested for Clique Percolation Method (http://cfinder.org/)  and The Louvain Method (http://perso.uclouvain.be/vincent.blondel/research/louvain.html).
3.	For each group and each timeframe calculate the user importance measure e.g. degree centrality, betweenness centrality, closeness centrality, page rank, social position, etc. To check how different user importance measures affects GED method please read Saganowski S., Bródka P., Kazienko P.: Influence of the User Importance Measure on the Group Evolution Discovery. Foundations of Computing and Decision Sciences, Volume 37, Issue 4, Pages 293-303, 2012. (http://arxiv.org/abs/1301.1534)
4.	Create a new database in Microsoft SQL Server and run the SQL script presented below (you can also copy paste this whole file into Microsoft SQL Server Management Studio)
5.	Import  your data into Groups_with_importance_measure table. The structure of the table is node id, group id, timeframe no., user importance measure value. U can use built in SQL Server ‘import data’ tool.
6.	Execute the GED procedure e.g. EXEC	[dbo].[GED]
Method parameters 
@timeframe - Default 1. The first timeframe number, the timeframes numbers have to be consecutive integers i.e. 1,2,3,..,n-1,n. 
@a_tres - Default 50. Percentage threshold for inclusion of group1 in group2 needed to satisfy requirements, the algorithm will iterate from threshold to 100 with 10 step i.e. 50, 60, 70, 80, 90, 100
@b_tres - Default 50. Percentage threshold for inclusion of group2 in group1 needed to satisfy requirements, the algorithm will iterate from threshold to 100 with 10 step i.e. 50, 60, 70, 80, 90, 100
@fd_tres - Default 10. forming/dissolving threshold
7.	The results can be found in GED_evolution table.
8.	Analyse and enjoy :)
*/

--------------------------------------------------------------------------
--SQL Script v0.1 11.07.2013----------------------------------------------
--------------------------------------------------------------------------

--------------------------------------------------------------------------
--create table for nodes, their communities and their importance measure--
--------------------------------------------------------------------------

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Groups_with_importance_measure](
	[node_id] [int] NOT NULL,
	[group_id] [int] NOT NULL,
	[timeframe] [int] NOT NULL,
	[importance_measure] [float] NOT NULL,
 CONSTRAINT [PK_Groups_with_importance_measure] PRIMARY KEY CLUSTERED 
(
	[node_id] ASC,
	[group_id] ASC,
	[timeframe] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
--------------------------------------------------------------------------
--create table for the GED results----------------------------------------
--------------------------------------------------------------------------


CREATE TABLE [dbo].[GED_evolution](
	[id_matched] [int] IDENTITY(1,1) NOT NULL,
	[event_type] [varchar](30) NULL,
	[group1] [int] NULL,
	[timeframe1] [tinyint] NULL,
	[group2] [int] NULL,
	[timeframe2] [tinyint] NULL,
	[alpha] [tinyint] NULL, -- inclusion of group1 in group2
	[beta] [tinyint] NULL, --inclusion of group2 in group1
	[threshold] [varchar](50) NULL)
	
	
--------------------------------------------------------------------------
-- GED Method-------------------------------------------------------------
--------------------------------------------------------------------------


SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GED]
	@timeframe int = 1, --the first timeframe number, the timeframes numbers have to be consecutive integers i.e. 1,2,3,..,n-1,n
	@a_tres int = 50, --percentage threshold for inclusion of group1 in group2 needed to satisfy requirements, the algorithm will iterate from threshold to 100 with 10 step i.e. 50, 60, 70, 80, 90, 100
	@b_tres int = 50, --percentage threshold for inclusion of group2 in group1 needed to satisfy requirements, the algorithm will iterate from threshold to 100 with 10 step i.e. 50, 60, 70, 80, 90, 100
	@fd_tres int = 10 --forming/dissolving threshold
AS
	SET NOCOUNT ON;
	
	DECLARE @timeframes_no int --number of timeframes
	DECLARE @group1 int --currently processed group in T1
	DECLARE @group2 int --currently processed group in T2
	DECLARE @t1_no int --number of groups in T1
	DECLARE @t2_no int --number of groups in T2
	DECLARE @g1_size int --number of nodes in group1
	DECLARE @g2_size int
	DECLARE @g1g2 int --intersection
	DECLARE @sr1 float --sum of ranking of selected nodes in group1
	DECLARE @sr2 float
	DECLARE @tr1 float --total ranking in group1
	DECLARE @tr2 float
	DECLARE @a int --inclusion of group1 in group2
	DECLARE @b int --inclusion of group2 in group1
	DECLARE @dissolve int
	DECLARE @form int
	DECLARE @tres varchar(10)
	DECLARE @a_tres_tmp int 
	DECLARE @b_tres_tmp int 

	SET @a_tres_tmp = @a_tres; 
	SET @b_tres_tmp = @b_tres; 

	SET @group1 = 0;
	SET @group2 = 0;
	SET @g1g2 = 0;
	
	truncate table [GED_evolution]
	
	CREATE TABLE #Gr1
	(
		node_id int PRIMARY KEY,
		sp float
	)

	CREATE TABLE #Gr2
	(
		node_id int PRIMARY KEY,
		sp float
	)


	WHILE @a_tres < 110
	BEGIN


	WHILE @b_tres < 110
	BEGIN

	SET @tres = CONVERT(varchar(3), @a_tres) + '_' + CONVERT(varchar(3), @b_tres);
	SET @timeframes_no = (SELECT COUNT(DISTINCT timeframe) FROM Groups_with_importance_measure);

	WHILE @timeframe <= @timeframes_no
	BEGIN

		SET @t1_no = (SELECT COUNT(DISTINCT group_id) FROM Groups_with_importance_measure WHERE timeframe = @timeframe);
		SET @t2_no = (SELECT COUNT(DISTINCT group_id) FROM Groups_with_importance_measure WHERE timeframe = @timeframe + 1);

		WHILE @group1 < @t1_no
		BEGIN
			INSERT INTO #Gr1
			SELECT node_id, importance_measure
			FROM Groups_with_importance_measure
			WHERE group_id = @group1 AND timeframe = @timeframe
			ORDER BY importance_measure
			
			SET @dissolve = 1;

			WHILE @group2 < @t2_no
			BEGIN
				INSERT INTO #Gr2 
				SELECT node_id, importance_measure

				FROM Groups_with_importance_measure
				WHERE group_id = @group2 AND timeframe = @timeframe + 1
				ORDER BY importance_measure

				SET @g1_size = (SELECT COUNT(*) FROM #Gr1);
				SET @g2_size = (SELECT COUNT(*) FROM #Gr2);
				SET @g1g2 = (SELECT COUNT(*) FROM (SELECT node_id FROM #Gr1 INTERSECT SELECT node_id FROM #Gr2) A);
				SET @sr1 = (SELECT SUM(sp) FROM #Gr1 WHERE node_id IN (SELECT node_id FROM #Gr1 INTERSECT SELECT node_id FROM #Gr2));
				SET @tr1 = (SELECT SUM(sp) FROM #Gr1);
				SET @sr2 = (SELECT SUM(sp) FROM #Gr2 WHERE node_id IN (SELECT node_id FROM #Gr1 INTERSECT SELECT node_id FROM #Gr2));
				SET @tr2 = (SELECT SUM(sp) FROM #Gr2);

				--calculating inclusion
				SET @a =  (1.0 * (@g1g2) / @g1_size) * (1.0 * (@sr1) / (@tr1)) * 100;
				SET @b =  (1.0 * (@g1g2) / @g2_size) * (1.0 * (@sr2) / (@tr2)) * 100;		

				--looking for dissolving
				IF (@dissolve = 1 AND (@a > @fd_tres OR @b > @fd_tres))
					SET @dissolve = 0;

				IF (@g1_size >= @g2_size)
				BEGIN
					IF (@a >= @a_tres) -- g1 > g2  AND  a > tres
					BEGIN
						IF (@b >= @b_tres) -- g1 > g2  AND  a > tres AND b > tres

							INSERT INTO GED_evolution VALUES ('shrinking', @group1, @timeframe, @group2, @timeframe + 1, @a, @b, @tres);
						ELSE

							INSERT INTO GED_evolution VALUES ('splitting/shrinking', @group1, @timeframe, @group2, @timeframe + 1, @a, @b, @tres);
					END
					ELSE -- g1 > g2  AND  a < tres
					BEGIN
						IF (@b >= @b_tres) -- g1 > g2  AND  a < tres AND b > tres

							INSERT INTO GED_evolution VALUES ('splitting/shrinking', @group1, @timeframe, @group2, @timeframe + 1, @a, @b, @tres);
														
					END
				END
				ELSE -- g1 < g2
				BEGIN
					IF (@a >= @a_tres) -- g1 < g2  AND  a > tres
					BEGIN
						IF (@b >= @b_tres) -- g1 < g2  AND a > tres AND b > tres

							INSERT INTO GED_evolution VALUES ('growing', @group1, @timeframe, @group2, @timeframe + 1, @a, @b, @tres);
						ELSE -- g1 < g2  AND a > tres AND b < tres

							INSERT INTO GED_evolution VALUES ('merging/growing', @group1, @timeframe, @group2, @timeframe + 1, @a, @b, @tres);
					END
					ELSE -- g1 < g2  AND a < tres
					BEGIN
						IF (@b >= @b_tres) -- g1 < g2  AND a < tres AND b < tres
						
							INSERT INTO GED_evolution VALUES ('merging/growing', @group1, @timeframe, @group2, @timeframe + 1, @a, @b, @tres);
						
					END
				END
				SET @group2 = @group2 + 1;
				TRUNCATE TABLE #Gr2
			END

			--dissolving
			IF (@dissolve = 1)

				INSERT INTO GED_evolution VALUES ('dissolving', @group1, @timeframe, null, @timeframe + 1, @a, @b, @tres);

			SET @group1 = @group1 + 1;
			TRUNCATE TABLE #Gr1
			SET @group2 = 0;
		END

		SET @group1 = 0;
		SET @group2 = 0;

--only for forming!!!!
		WHILE @group2 < @t2_no
		BEGIN
			INSERT INTO #Gr2
			SELECT node_id, importance_measure

			FROM Groups_with_importance_measure
			WHERE group_id = @group2 AND timeframe = @timeframe + 1
			ORDER BY importance_measure
			
			SET @form = 1;

			WHILE @group1 < @t1_no
			BEGIN
				INSERT INTO #Gr1 --select top 30 PERCENT?
				SELECT node_id, importance_measure

				FROM Groups_with_importance_measure
				WHERE group_id = @group1 AND timeframe = @timeframe
				ORDER BY importance_measure

				SET @g1_size = (SELECT COUNT(*) FROM #Gr1);
				SET @g2_size = (SELECT COUNT(*) FROM #Gr2);
				SET @g1g2 = (SELECT COUNT(*) FROM (SELECT node_id FROM #Gr1 INTERSECT SELECT node_id FROM #Gr2) A);
				SET @sr1 = (SELECT SUM(sp) FROM #Gr1 WHERE node_id IN (SELECT node_id FROM #Gr1 INTERSECT SELECT node_id FROM #Gr2));
				SET @tr1 = (SELECT SUM(sp) FROM #Gr1);
				SET @sr2 = (SELECT SUM(sp) FROM #Gr2 WHERE node_id IN (SELECT node_id FROM #Gr1 INTERSECT SELECT node_id FROM #Gr2));
				SET @tr2 = (SELECT SUM(sp) FROM #Gr2);

				--calculating inclusion
				SET @a =  (1.0 * (@g1g2) / @g1_size) * (1.0 * (@sr1) / (@tr1)) * 100;
				SET @b =  (1.0 * (@g1g2) / @g2_size) * (1.0 * (@sr2) / (@tr2)) * 100;

				--looking for forming
				IF (@form = 1 AND (@a > @fd_tres OR @b > @fd_tres))
					SET @form = 0;

				SET @group1 = @group1 + 1;
				TRUNCATE TABLE #Gr1
			END

			--forming
			IF (@form = 1)

				INSERT INTO GED_evolution VALUES ('forming', null, @timeframe, @group2, @timeframe + 1, @a, @b, @tres);

			SET @group2 = @group2 + 1;
			TRUNCATE TABLE #Gr2
			SET @group1 = 0;
		END

		SET @timeframe = @timeframe + 1;
		SET @group1 = 0;
		SET @group2 = 0;
	END

	SET @b_tres = @b_tres + 10;
	SET @timeframe = 1;
	END

	SET @a_tres = @a_tres + 10;
	SET @b_tres = 50;
	END


	DROP TABLE #Gr1
	DROP TABLE #Gr2

	--------------------------------------------------
	--splitting/shrinking and merging/growing update--
	--------------------------------------------------


	DECLARE @g1 int
	DECLARE @t1 int
	DECLARE @g2 int
	DECLARE @t2 int
	
	SET @a_tres = @a_tres_tmp; 
	SET @b_tres = @b_tres_tmp; 

	WHILE @a_tres < 101
	BEGIN

	WHILE @b_tres < 101
	BEGIN

	SET @tres = CONVERT(varchar(3), @a_tres) + '_' + CONVERT(varchar(3), @b_tres);

	DECLARE spl CURSOR FOR SELECT group1, timeframe1 FROM GED_evolution WHERE threshold = @tres AND event_type = 'splitting/shrinking';
	DECLARE mer CURSOR FOR SELECT group2, timeframe2 FROM GED_evolution WHERE threshold = @tres AND event_type = 'merging/growing';

	OPEN spl;

	FETCH NEXT FROM spl
	INTO @g1, @t1;

	WHILE @@FETCH_STATUS = 0
	BEGIN
		IF ((SELECT COUNT(group1) FROM GED_evolution WHERE threshold = @tres AND event_type = 'splitting/shrinking' AND group1 = @g1 AND timeframe1 = @t1) > 1
			OR (SELECT COUNT(group1) FROM GED_evolution WHERE threshold = @tres AND event_type IN ('shrinking', 'growing') AND group1 = @g1 AND timeframe1 = @t1) > 0)
		BEGIN
			UPDATE GED_evolution
			SET event_type = 'splitting'
			WHERE threshold = @tres AND group1 = @g1 AND timeframe1 = @t1 AND event_type = 'splitting/shrinking'
		END
		ELSE
		BEGIN
			UPDATE GED_evolution
			SET event_type = 'shrinking'
			WHERE threshold = @tres AND group1 = @g1 AND timeframe1 = @t1 AND event_type = 'splitting/shrinking'
		END

		FETCH NEXT FROM spl
		INTO @g1, @t1;
	END
	CLOSE spl;
	DEALLOCATE spl;


	OPEN mer;

	FETCH NEXT FROM mer
	INTO @g2, @t2;

	WHILE @@FETCH_STATUS = 0
	BEGIN
		IF ((SELECT COUNT(group2) FROM GED_evolution WHERE threshold = @tres AND event_type = 'merging/growing' AND group2 = @g2 AND timeframe2 = @t2) > 1
			OR (SELECT COUNT(group2) FROM GED_evolution WHERE threshold = @tres AND event_type IN ('shrinking', 'growing') AND group2 = @g2 AND timeframe2 = @t2) > 0)
		BEGIN
			UPDATE GED_evolution
			SET event_type = 'merging'
			WHERE threshold = @tres AND group2 = @g2 AND timeframe2 = @t2 AND event_type = 'merging/growing'
		END
		ELSE
		BEGIN
			UPDATE GED_evolution
			SET event_type = 'growing'
			WHERE threshold = @tres AND group2 = @g2 AND timeframe2 = @t2 AND event_type = 'merging/growing'
		END

		FETCH NEXT FROM mer
		INTO @g2, @t2;
	END
	CLOSE mer;
	DEALLOCATE mer;

	SET @b_tres = @b_tres + 10;
	END

	SET @a_tres = @a_tres + 10;
	SET @b_tres = 50;
	END


	--update growing and shrinking, SET continue when size is the same
	UPDATE GED_evolution
	SET event_type = 'continuing'
	WHERE event_type IN ('shrinking', 'growing')
	AND ((SELECT COUNT(node_id) FROM Groups_with_importance_measure WHERE group_id = group1 and timeframe = timeframe1) = (SELECT COUNT(node_id) FROM Groups_with_importance_measure WHERE group_id = group2 and timeframe = timeframe2))
GO
	







