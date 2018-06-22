USE playground;
GO

IF SCHEMA_ID(N'RubiksCube3x3x3') IS NULL EXEC('CREATE SCHEMA RubiksCube3x3x3 AUTHORIZATION dbo;');
GO

DROP TABLE IF EXISTS RubiksCube3x3x3.CubeStatus;
GO

CREATE TABLE RubiksCube3x3x3.CubeStatus (
	CubeStatusID BIGINT IDENTITY(1, 1) NOT NULL,
	CubeStatus CHAR(54) NOT NULL,
	IsSolved BIT NOT NULL CONSTRAINT DFT_RubiksCube3x3x3_CubeStatus_IsSolved DEFAULT(0),
	Moves TINYINT NOT NULL

	CONSTRAINT PK_RubiksCube3x3x3_CubeStatus PRIMARY KEY CLUSTERED (CubeStatusID)
);
GO

CREATE UNIQUE NONCLUSTERED INDEX IX_RubiksCube3x3x3_CubeStatus_CubeStatus ON RubiksCube3x3x3.CubeStatus (CubeStatus);
GO

INSERT INTO RubiksCube3x3x3.CubeStatus
        ( --CubeStatusID ,
          CubeStatus ,
          IsSolved ,
          Moves
        )
VALUES  ( --0 , -- CubeStatusID - bigint
          'WWWWWWWWWOOOOOOOOOGGGGGGGGGRRRRRRRRRBBBBBBBBBYYYYYYYYY' , -- CubeStatus - char(54)
          1 , -- IsSolved - bit
          0  -- Moves - tinyint
        );
GO

SELECT * FROM RubiksCube3x3x3.CubeStatus;
GO

DROP TABLE IF EXISTS RubiksCube3x3x3.CubeMove;

CREATE TABLE RubiksCube3x3x3.CubeMove (
	CubeMoveID TINYINT IDENTITY(1, 1) NOT NULL,
	CubeMove VARCHAR(2) NOT NULL,
	CubeAntiMove VARCHAR(2) NOT NULL
);
GO

INSERT INTO RubiksCube3x3x3.CubeMove
        ( --CubeMoveID ,
          CubeMove ,
          CubeAntiMove
        )
VALUES  ( --0 , -- CubeMoveID - tinyint
          'U' , -- CubeMove - char(2)
          'U'''  -- CubeAntiMove - char(2)
        ), ('U''', 'U'), ('U2', 'U2'),
		('L', 'L'''), ('L''', 'L'), ('L2', 'L2'),
		('F', 'F'''), ('F''', 'F'), ('F2', 'F2'),
		('R', 'R'''), ('R''', 'R'), ('R2', 'R2'),
		('B', 'B'''), ('B''', 'B'), ('B2', 'B2'),
		('D', 'D'''), ('D''', 'D'), ('D2', 'D2');
GO

SELECT * FROM RubiksCube3x3x3.CubeMove;
GO
