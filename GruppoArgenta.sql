USE DW1729;
GO

/* Landing area: Inizio */

SELECT Gusto ,
       DataOrdine ,
       DataSpedizione ,
       DataFattura ,
       Qta,
	   Prezzo

FROM GRUPPOARGENTA.OrdiniGruppoArgenta;
GO

DROP TABLE IF EXISTS GRUPPOARGENTA.Offerta;
GO

SELECT
	-- Chiavi
	N'JustCapsule' AS IDOfferta,

	-- Attributi
	N'Just capsule 037' AS Offerta,
	1 AS HasCanoneAnnuo,
	60.0 AS ImportoCanoneAnnuo,
	1 AS HasCostoAccessori,
	0.37 AS Prezzo037,
	0.39 AS Prezzo039,
	0.45 AS Prezzo045

INTO GRUPPOARGENTA.Offerta

UNION ALL SELECT N'CapsuleAssistance', N'Capsule & Assistance 045', 0, 0.0, 1, 0.45, 0.47, 0.49
UNION ALL SELECT N'AllService', N'All-service 055', 0, 0.0, 0, 0.55, 0.55, 0.55;
GO

DROP TABLE IF EXISTS GRUPPOARGENTA.Gusto;
GO

SELECT
	-- Chiavi
	N'R' AS IDGusto,

	-- Attributi
	N'Ristretto' AS Gusto,
	N'037' AS GruppoPrezzi

INTO GRUPPOARGENTA.Gusto

UNION ALL SELECT N'RI', N'RistrettoIntenso', N'039'
UNION ALL SELECT N'OI', N'OriginIndia', N'045'
UNION ALL SELECT N'OB', N'OriginBrazil', N'045';
GO

DROP TABLE IF EXISTS GRUPPOARGENTA.Accessorio;
GO

SELECT
	-- Chiavi
	N'Zucchero' AS Articolo,

	-- Attributi
	0.2 AS CoefficienteImpiego,
	1.00 / 50.0 AS Prezzo

INTO GRUPPOARGENTA.Accessorio
UNION ALL SELECT N'Paletta', 0.2, 0.50 / 50.0
UNION ALL SELECT N'Bicchiere', 1.1, 0.50 / 50.0;
GO

/* Landing area: Fine */

/* Staging area: Inizio */

DROP VIEW IF EXISTS Staging.OffertaPrezzoView;
GO

CREATE VIEW Staging.OffertaPrezzoView
AS
WITH GustoUltimoPrezzoGruppoArgentaDettaglio
AS (
	SELECT
		Gusto,
		Prezzo,
		ROW_NUMBER() OVER (PARTITION BY Gusto ORDER BY DataOrdine DESC) AS rn

	FROM GRUPPOARGENTA.OrdiniGruppoArgenta
)
SELECT
	N'GA' AS IDOfferta,
	N'Gruppo Argenta' AS Offerta,
	G.IDGusto,
	G.Gusto,
	GUPGAD.Prezzo

FROM GustoUltimoPrezzoGruppoArgentaDettaglio GUPGAD
INNER JOIN GRUPPOARGENTA.Gusto G ON G.Gusto = GUPGAD.Gusto
WHERE GUPGAD.rn = 1

UNION ALL

SELECT
	O.IDOfferta,
	O.Offerta,
	G.IDGusto,
	G.Gusto,
	CASE G.GruppoPrezzi
		WHEN N'037' THEN O.Prezzo037
		WHEN N'039' THEN O.Prezzo039
		WHEN N'045' THEN O.Prezzo045
	END AS Prezzo

FROM GRUPPOARGENTA.Offerta O
CROSS JOIN GRUPPOARGENTA.Gusto G;
GO

DROP TABLE IF EXISTS Staging.OffertaPrezzo;
GO

SELECT * INTO Staging.OffertaPrezzo FROM Staging.OffertaPrezzoView;
GO

DROP VIEW IF EXISTS Staging.QtaSimulazioniView;
GO

CREATE VIEW Staging.QtaSimulazioniView
AS
WITH StoricoOrdini
AS (
	SELECT
		SUM(OGA.Qta) AS NumeroCialde,
		DATEDIFF(DAY, MIN(OGA.DataOrdine), MAX(OGA.DataOrdine)) AS Giorni

	FROM GRUPPOARGENTA.OrdiniGruppoArgenta OGA
),
RangeQta
AS (
	SELECT
		CONVERT(INT, ROUND(0.5 * SO.NumeroCialde / SO.Giorni * 365.0 / 100.0, 0) * 100) AS QtaMinima,
		CONVERT(INT, ROUND(1.0 * SO.NumeroCialde / SO.Giorni * 365.0 / 100.0, 0) * 100) AS QtaMassima

	FROM StoricoOrdini SO
),
Numbers
AS (
	SELECT TOP 100 ROW_NUMBER() OVER (ORDER BY O.object_id) AS Number FROM sys.objects O
)
SELECT
	CONVERT(SMALLINT, RQ.QtaMinima + (N.Number - 1) * 100) AS QtaSimulazione

FROM RangeQta RQ
INNER JOIN Numbers N ON N.Number <= (SELECT (RQ.QtaMassima - RQ.QtaMinima) / 100 + 1 FROM RangeQta RQ);
GO

DROP TABLE IF EXISTS Staging.QtaSimulazioni;
GO

SELECT * INTO Staging.QtaSimulazioni FROM Staging.QtaSimulazioniView;
GO

DROP VIEW IF EXISTS Staging.GustoCoefficienteIncidenzaView;
GO

CREATE VIEW Staging.GustoCoefficienteIncidenzaView
AS
SELECT
	G.IDGusto,
	1.0 * SUM(OGA.Qta) / (SELECT SUM(Qta) FROM GRUPPOARGENTA.OrdiniGruppoArgenta) AS CoefficienteIncidenza

FROM GRUPPOARGENTA.OrdiniGruppoArgenta OGA
INNER JOIN GRUPPOARGENTA.Gusto G ON G.Gusto = OGA.Gusto
GROUP BY G.IDGusto;
GO

DROP TABLE IF EXISTS Staging.GustoCoefficienteIncidenza;
GO

SELECT * INTO Staging.GustoCoefficienteIncidenza FROM Staging.GustoCoefficienteIncidenzaView;
GO

/* Staging area: Fine */

/* DW area: Inizio */

-- Cleanup DW tables: Inizio

DROP TABLE IF EXISTS dbo.FactOrdini;
GO

DROP TABLE IF EXISTS dbo.FactProiezioni;
GO

DROP TABLE IF EXISTS dbo.FactSimulazioni;
GO

DROP TABLE IF EXISTS dbo.DimOfferta;
GO

DROP TABLE IF EXISTS dbo.DimArticolo;
GO

DROP TABLE IF EXISTS dbo.DimData;
GO

-- Cleanup DW tables: Fine

DECLARE @start_year INT = 2015;
DECLARE @end_year INT = 2016;

WITH Tally
AS (
	SELECT NULL AS t
	UNION ALL SELECT NULL
),
Numbers
AS (
	SELECT TOP 1000 ROW_NUMBER() OVER (ORDER BY T0.t) AS Number
	FROM Tally T0
	CROSS JOIN Tally T1
	CROSS JOIN Tally T2
	CROSS JOIN Tally T3
	CROSS JOIN Tally T4
	CROSS JOIN Tally T5
	CROSS JOIN Tally T6
	CROSS JOIN Tally T7
	CROSS JOIN Tally T8
	CROSS JOIN Tally T9
	CROSS JOIN Tally T10
),
Dates
AS (
	SELECT DATEADD(dd, N.Number-1, DATEADD(yy, @start_year-1900, 0)) AS PKData
	FROM Numbers N
	WHERE DATEADD(dd, N.Number-1, DATEADD(yy, @start_year-1900, 0)) < DATEADD(yy, @end_year-1900+1, 0)
)
SELECT
	-- Chiavi
	CAST(Dates.PKData AS DATE) AS PKData,
	CAST(Dates.PKData AS DATE) AS Data,

	YEAR(Dates.PKData) AS Anno,
	MONTH(Dates.PKData) AS Mese,
	DATENAME(MONTH, Dates.PKData) AS MeseDescrizione,
	DAY(Dates.PKData) AS Giorno

INTO dbo.DimData
FROM Dates;
GO

ALTER TABLE dbo.DimData ALTER COLUMN PKData DATE NOT NULL;
ALTER TABLE dbo.DimData ALTER COLUMN Data DATE NOT NULL;
GO

ALTER TABLE dbo.DimData ADD CONSTRAINT PK_DimData PRIMARY KEY CLUSTERED (PKData);
GO

CREATE TABLE dbo.DimOfferta (
	PKOfferta			TINYINT IDENTITY(1, 1) NOT NULL CONSTRAINT PK_DimOfferta PRIMARY KEY CLUSTERED,
	IDOfferta			NVARCHAR(20) NOT NULL,
	Offerta				NVARCHAR(40) NOT NULL,
	HasCanoneAnnuo		BIT NOT NULL,
	ImportoCanoneAnnuo	DECIMAL(10, 2) NOT NULL,
	HasCostoAccessori	BIT NOT NULL,
	Prezzo037			DECIMAL(5, 2) NOT NULL,
	Prezzo039			DECIMAL(5, 2) NOT NULL,
	Prezzo045			DECIMAL(5, 2) NOT NULL
);
GO

CREATE TABLE dbo.DimArticolo (
	PKArticolo			TINYINT IDENTITY(1, 1) NOT NULL CONSTRAINT PK_DimArticolo PRIMARY KEY CLUSTERED,
	Articolo			NVARCHAR(40) NOT NULL,
	TipoArticolo		NVARCHAR(20) NOT NULL,
	GruppoPrezzi		NVARCHAR(3) NOT NULL
);
GO

CREATE TABLE dbo.FactOrdini (
	-- Chiavi
	PKDataOrdine		DATE NOT NULL CONSTRAINT FK_FactOrdini_PKDataOrdine REFERENCES dbo.DimData (PKData),
	PKArticolo			TINYINT NOT NULL CONSTRAINT FK_FactOrdini_PKArticolo REFERENCES dbo.DimArticolo (PKArticolo),

	-- Misure
	Qta					INT NOT NULL,
	Prezzo				DECIMAL(10, 2) NOT NULL

	CONSTRAINT PK_FactOrdini PRIMARY KEY CLUSTERED (PKDataOrdine, PKArticolo)
);
GO

CREATE TABLE dbo.FactProiezioni (
	-- Chiavi
	PKData				DATE NOT NULL CONSTRAINT FK_FactProiezioni_PKData REFERENCES dbo.DimData (PKData),
	PKArticolo			TINYINT NOT NULL CONSTRAINT FK_FactProiezioni_PKArticolo REFERENCES dbo.DimArticolo (PKArticolo),
	PKOfferta			TINYINT NOT NULL CONSTRAINT FK_FactProiezioni_PKOfferta REFERENCES dbo.DimOfferta (PKOfferta),

	Qta					DECIMAL(10, 2) NOT NULL,
	Importo				DECIMAL(10, 2) NOT NULL,

	CONSTRAINT PK_FactProiezioni PRIMARY KEY CLUSTERED (PKData, PKArticolo, PKOfferta)
);
GO

CREATE TABLE dbo.FactSimulazioni (
	-- Chiavi
	PKOfferta			TINYINT NOT NULL CONSTRAINT FK_FactSimulazioni_PKOfferta REFERENCES dbo.DimOfferta (PKOfferta),
	PKArticolo			TINYINT NOT NULL CONSTRAINT FK_FactSimulazioni_PKArticolo REFERENCES dbo.DimArticolo (PKArticolo),
	QtaSimulazione		INT NOT NULL,

	Importo				DECIMAL(10, 2) NOT NULL,

	CONSTRAINT PK_FactSimulazioni PRIMARY KEY CLUSTERED (PKOfferta, PKArticolo, QtaSimulazione)
);
GO

DROP VIEW IF EXISTS dbo.FactProiezioniView;
GO

CREATE VIEW dbo.FactProiezioniView
AS
WITH DateOrdini
AS (
	SELECT
		PKDataOrdine,
		DENSE_RANK() OVER (ORDER BY PKDataOrdine) AS rn

	FROM dbo.FactOrdini
	GROUP BY PKDataOrdine
)
--SELECT
--	FO.PKDataOrdine AS PKData,
--	FO.PKArticolo,
--	DO.PKOfferta,

--	FO.Qta,
--	FO.Qta * FO.Prezzo AS Importo

--FROM dbo.FactOrdini FO
--INNER JOIN dbo.DimArticolo DA ON DA.PKArticolo = FO.PKArticolo AND DA.TipoArticolo = N'Caffè'
--INNER JOIN dbo.DimOfferta DO ON DO.IDOfferta = N'GA'

--UNION ALL

SELECT
	FO.PKDataOrdine AS PKData,
	FO.PKArticolo,
	DO.PKOfferta,

	FO.Qta,
	FO.Qta * OP.Prezzo AS Importo

FROM dbo.FactOrdini FO
INNER JOIN dbo.DimArticolo DA ON DA.PKArticolo = FO.PKArticolo AND DA.TipoArticolo = N'Caffè'
INNER JOIN Staging.OffertaPrezzo OP ON OP.Gusto = DA.Articolo
INNER JOIN dbo.DimOfferta DO ON OP.Offerta = DO.Offerta

UNION ALL

SELECT
	FO.PKDataOrdine AS PKData,
	DA.PKArticolo,
	DO.PKOfferta,

	FO.Qta * A.CoefficienteImpiego AS Qta,
	FO.Qta * A.CoefficienteImpiego * A.Prezzo AS Importo

FROM (
	SELECT
		PKDataOrdine,
		SUM(Qta) AS Qta

	FROM dbo.FactOrdini
	GROUP BY PKDataOrdine
) FO
INNER JOIN dbo.DimOfferta DO ON DO.HasCostoAccessori = 1
CROSS JOIN GRUPPOARGENTA.Accessorio A
INNER JOIN dbo.DimArticolo DA ON DA.Articolo = A.Articolo AND DA.TipoArticolo = N'Accessorio'

UNION ALL

SELECT
	DtO.PKDataOrdine AS PKData,
	DA.PKArticolo,
	DO.PKOfferta,
	0 AS Qta,
	DO.ImportoCanoneAnnuo / 365.0 * DATEDIFF(DAY, DtO0.PKDataOrdine, DtO.PKDataOrdine) AS Importo

FROM dbo.DimOfferta DO
INNER JOIN dbo.DimArticolo DA ON DA.TipoArticolo = N'Canone'
CROSS JOIN DateOrdini DtO
INNER JOIN DateOrdini DtO0 ON DtO0.rn = DtO.rn - 1
WHERE DO.HasCanoneAnnuo = 1;
GO

DROP VIEW IF EXISTS dbo.FactSimulazioniView;
GO

CREATE VIEW dbo.FactSimulazioniView
AS
WITH Simulazioni
AS (
	SELECT
		OP.Offerta,
		OP.Gusto,
		QS.QtaSimulazione,
		QS.QtaSimulazione * GCI.CoefficienteIncidenza * OP.Prezzo AS Importo

	FROM Staging.QtaSimulazioni QS
	CROSS JOIN Staging.GustoCoefficienteIncidenza GCI
	INNER JOIN Staging.OffertaPrezzo OP ON OP.IDGusto = GCI.IDGusto
)
SELECT
	DO.PKOfferta,
	DA.PKArticolo,
	S.QtaSimulazione,

	S.Importo

FROM Simulazioni S
INNER JOIN dbo.DimArticolo DA ON DA.Articolo = S.Gusto AND DA.TipoArticolo = N'Caffè'
INNER JOIN dbo.DimOfferta DO ON DO.Offerta = S.Offerta

UNION ALL

SELECT
	DO.PKOfferta,
	DA.PKArticolo,
	S.QtaSimulazione,

	S.QtaSimulazione * A.CoefficienteImpiego * A.Prezzo AS Importo

FROM (
	SELECT DISTINCT
		S.Offerta,
		QtaSimulazione

	FROM Simulazioni S
) S
INNER JOIN dbo.DimOfferta DO ON DO.Offerta = S.Offerta AND DO.HasCostoAccessori = 1
CROSS JOIN GRUPPOARGENTA.Accessorio A
INNER JOIN dbo.DimArticolo DA ON DA.Articolo = A.Articolo AND DA.TipoArticolo = N'Accessorio'

UNION ALL

SELECT
	DO.PKOfferta,
	DA.PKArticolo,
	QS.QtaSimulazione,

	DO.ImportoCanoneAnnuo AS Importo

FROM Staging.QtaSimulazioni QS
INNER JOIN dbo.DimOfferta DO ON DO.HasCanoneAnnuo = 1
INNER JOIN dbo.DimArticolo DA ON DA.TipoArticolo = N'Canone';
GO
