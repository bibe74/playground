USE DW1729;
GO

CREATE SCHEMA ZAFIRA AUTHORIZATION dbo;
GO

SELECT * FROM ZAFIRA.SpeseCarburanteZafira;

/**
 * @table staging.T_SpeseCarburanteZafira
 * @description 

 * @depends 

SELECT TOP 1 * FROM 
*/

IF OBJECT_ID(N'staging.T_SpeseCarburanteZafiraView', N'V') IS NULL EXEC('CREATE VIEW staging.T_SpeseCarburanteZafiraView AS SELECT 1 AS fld;');
GO

ALTER VIEW staging.T_SpeseCarburanteZafiraView
AS
WITH SpeseCarburanteZafira
AS (
	SELECT
		ROW_NUMBER() OVER (ORDER BY Data) AS rn,
		Data,
        KmTotali,
        TipoCarburante,
        LocalitaDistributore,
        EuroMetano,
        EuroKgMetano,
        EuroBenzina,
        EuroLitroBenzina

	FROM ZAFIRA.SpeseCarburanteZafira
)
SELECT
	SCZ.rn,
    SCZ.Data,
    --SCZ.KmTotali,
    --SCZ.TipoCarburante,
	CASE WHEN SCZ.rn > 2 AND SCZ0.TipoCarburante = 'M' THEN SCZ.KmTotali - SCZ0.KmTotali END AS KmMetano,
	CASE WHEN SCZ.rn > 2 AND SCZ0.TipoCarburante = 'B' THEN SCZ.KmTotali - SCZ0.KmTotali END AS KmBenzina,
    SCZ.LocalitaDistributore,
    SCZ.EuroMetano,
    SCZ.EuroKgMetano,
    SCZ.EuroBenzina,
    SCZ.EuroLitroBenzina

FROM SpeseCarburanteZafira SCZ
LEFT JOIN SpeseCarburanteZafira SCZ0 ON SCZ0.rn = SCZ.rn - 1;
GO

--DROP TABLE staging.T_SpeseCarburanteZafira;
GO

IF OBJECT_ID(N'staging.T_SpeseCarburanteZafira', N'U') IS NULL
BEGIN
    SELECT TOP 0 IDENTITY(INT) AS PKSpeseCarburanteZafira, * INTO staging.T_SpeseCarburanteZafira FROM staging.T_SpeseCarburanteZafiraView ORDER BY rn;

    ALTER TABLE staging.T_SpeseCarburanteZafira ALTER COLUMN PKSpeseCarburanteZafira INT NOT NULL;

    ALTER TABLE staging.T_SpeseCarburanteZafira ADD CONSTRAINT PK_staging_T_SpeseCarburanteZafira PRIMARY KEY CLUSTERED (PKSpeseCarburanteZafira);

    --CREATE UNIQUE NONCLUSTERED INDEX IX_staging.T_SpeseCarburanteZafira_ ON staging.T_SpeseCarburanteZafira ();
END;
GO

TRUNCATE TABLE staging.T_SpeseCarburanteZafira;
GO

INSERT INTO staging.T_SpeseCarburanteZafira SELECT * FROM staging.T_SpeseCarburanteZafiraView ORDER BY rn;
GO

/**
 * @table staging.T_Distributore
 * @description 

 * @depends 

SELECT TOP 1 * FROM 
*/

IF OBJECT_ID(N'staging.T_DistributoreView', N'V') IS NULL EXEC('CREATE VIEW staging.T_DistributoreView AS SELECT 1 AS fld;');
GO

ALTER VIEW staging.T_DistributoreView
AS
SELECT
	LocalitaDistributore,
	COUNT(1) AS NumeroRifornimenti,
	LocalitaDistributore AS LocalitaDistributore_cleaned

FROM Staging.T_SpeseCarburanteZafira
GROUP BY LocalitaDistributore;
GO

--DROP TABLE staging.T_Distributore;
GO

IF OBJECT_ID(N'staging.T_Distributore', N'U') IS NULL
BEGIN
    SELECT TOP 0 IDENTITY(INT) AS PKDistributore, * INTO staging.T_Distributore FROM staging.T_DistributoreView;

    ALTER TABLE staging.T_Distributore ALTER COLUMN PKDistributore INT NOT NULL;

    ALTER TABLE staging.T_Distributore ADD CONSTRAINT PK_staging_T_Distributore PRIMARY KEY CLUSTERED (PKDistributore);

    --CREATE UNIQUE NONCLUSTERED INDEX IX_staging.T_Distributore_ ON staging.T_Distributore ();
END;
GO

TRUNCATE TABLE staging.T_Distributore;
GO

INSERT INTO staging.T_Distributore SELECT * FROM staging.T_DistributoreView;
GO

/**
 * @table dbo.DimDistributore
 * @description 

 * @depends 

SELECT TOP 1 * FROM 
*/

IF OBJECT_ID(N'dbo.DimDistributoreView', N'V') IS NULL EXEC('CREATE VIEW dbo.DimDistributoreView AS SELECT 1 AS fld;');
GO

ALTER VIEW dbo.DimDistributoreView
AS
SELECT DISTINCT
    D.LocalitaDistributore_cleaned AS Localita,
	CASE
	  WHEN CHARINDEX(')', D.LocalitaDistributore_cleaned) - CHARINDEX(N'(', D.LocalitaDistributore_cleaned) = 3 THEN SUBSTRING(D.LocalitaDistributore_cleaned, CHARINDEX(N'(', D.LocalitaDistributore_cleaned) + 1, 2)
	  WHEN CHARINDEX(')', D.LocalitaDistributore_cleaned) - CHARINDEX(N'(', D.LocalitaDistributore_cleaned) = 4 THEN N''
	  WHEN CHARINDEX('Brescia', D.LocalitaDistributore_cleaned) > 0 THEN N'BS'
	  WHEN CHARINDEX('Cremona', D.LocalitaDistributore_cleaned) > 0 THEN N'CR'
	  WHEN CHARINDEX('Aosta', D.LocalitaDistributore_cleaned) > 0 THEN N'AO'
	  WHEN CHARINDEX('Bolzano', D.LocalitaDistributore_cleaned) > 0 THEN N'BZ'
	  WHEN CHARINDEX('Como', D.LocalitaDistributore_cleaned) > 0 THEN N'CO'
	  WHEN CHARINDEX('Firenze', D.LocalitaDistributore_cleaned) > 0 THEN N'FI'
	  WHEN CHARINDEX('Grosseto', D.LocalitaDistributore_cleaned) > 0 THEN N'GR'
	  WHEN CHARINDEX('Lucca', D.LocalitaDistributore_cleaned) > 0 THEN N'LU'
	  WHEN CHARINDEX('Milano', D.LocalitaDistributore_cleaned) > 0 THEN N'MI'
	  WHEN CHARINDEX('Parma', D.LocalitaDistributore_cleaned) > 0 THEN N'PR'
	  WHEN CHARINDEX('Pisa', D.LocalitaDistributore_cleaned) > 0 THEN N'PI'
	  WHEN CHARINDEX('Reggio Emilia', D.LocalitaDistributore_cleaned) > 0 THEN N'RE'
	  WHEN CHARINDEX('Sassari', D.LocalitaDistributore_cleaned) > 0 THEN N'SS'
	END AS Provincia,
	CASE WHEN CHARINDEX(')', D.LocalitaDistributore_cleaned) - CHARINDEX(N'(', D.LocalitaDistributore_cleaned) = 4 THEN SUBSTRING(D.LocalitaDistributore_cleaned, CHARINDEX(N'(', D.LocalitaDistributore_cleaned) + 1, 3) ELSE N'ITA' END AS Nazione

FROM Staging.T_Distributore D
WHERE D.LocalitaDistributore_cleaned IS NOT NULL;
GO

--DROP TABLE dbo.DimDistributore;
GO

IF OBJECT_ID(N'dbo.DimDistributore', N'U') IS NULL
BEGIN
    SELECT TOP 0 IDENTITY(INT) AS PKDistributore, * INTO dbo.DimDistributore FROM dbo.DimDistributoreView;

    ALTER TABLE dbo.DimDistributore ADD CONSTRAINT PK_dbo_DimDistributore PRIMARY KEY CLUSTERED (PKDistributore);

    --ALTER TABLE dbo.DimDistributore ALTER COLUMN PK<nullable_column> BIGINT NOT NULL;

    CREATE UNIQUE NONCLUSTERED INDEX IX_dbo_DimDistributore_Localita ON dbo.DimDistributore (Localita);
END;
GO

TRUNCATE TABLE dbo.DimDistributore;
GO

INSERT INTO dbo.DimDistributore SELECT * FROM dbo.DimDistributoreView;
GO

SET IDENTITY_INSERT dbo.DimDistributore ON;
INSERT INTO dbo.DimDistributore
(
	PKDistributore,
    Localita,
    Provincia,
    Nazione
)
VALUES
(   -1,
	N'', -- Localita - nvarchar(255)
    N'', -- Provincia - nvarchar(2)
    N''  -- Nazione - nvarchar(3)
),(   -101,
	N'<???>', -- Localita - nvarchar(255)
    N'??', -- Provincia - nvarchar(2)
    N'???'  -- Nazione - nvarchar(3)
)
SET IDENTITY_INSERT dbo.DimDistributore OFF;
GO

SELECT
    SCZ.PKSpeseCarburanteZafira,
    SCZ.Data,
	COALESCE(DD.PKDistributore, CASE WHEN D.LocalitaDistributore IS NULL THEN -1 ELSE -101 END) AS PKDistributore,
    SCZ.KmMetano,
    SCZ.KmBenzina,
    SCZ.EuroMetano,
    SCZ.EuroKgMetano,
    SCZ.EuroBenzina,
    SCZ.EuroLitroBenzina

FROM Staging.T_SpeseCarburanteZafira SCZ
LEFT JOIN Staging.T_Distributore D ON D.LocalitaDistributore = SCZ.LocalitaDistributore
LEFT JOIN dbo.DimDistributore DD ON DD.Localita = D.LocalitaDistributore_cleaned;
