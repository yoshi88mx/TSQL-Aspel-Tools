DECLARE @ALMACENDESTINO INT = 1
DECLARE @ALMACENORIGEN INT = 3

--SE DAN DE ALTA PRODUCTOS EN EL ALMACEN DESTINO, SOLO AQUELLOS QUE EXISTEN EN EL ORIGEN Y NO EN EL DESTINO
INSERT INTO MULT01
SELECT CVE_ART, 1, 'A', '',0,0,0,0,NULL,GETDATE() FROM MULT01 WHERE CVE_ALM = @ALMACENORIGEN AND CVE_ART NOT IN (SELECT CVE_ART FROM MULT01 WHERE CVE_ALM = @ALMACENDESTINO)


--SE TRASPASA EL INVENTARIO
DECLARE @CURRENTPRODUCT VARCHAR(20)
DECLARE @CURRENTEXIST FLOAT
DECLARE @PREVIOUSTEXIST FLOAT
DECLARE @NEWEXIST FLOAT
DECLARE @GLOBALEXIST FLOAT
DECLARE @COST FLOAT
DECLARE @PREVIOUSTNUMMOV INT
DECLARE @LASTNUMMOV int
DECLARE @LASTFOLIO INT
--SE OPTIENE EL ULTIMO FOLIO DE LA TABLA DE CONTROL
set @LASTFOLIO = (SELECT ULT_CVE FROM TBLCONTROL01 WHERE ID_TABLA = 32)
--SE OPTIENE EL ULTIMO NUMERO DE MOVIMIENTO DE LA TABLA DE CONTROL
set @LASTNUMMOV = (SELECT ULT_CVE FROM TBLCONTROL01 WHERE ID_TABLA = 44)
DECLARE TraspasoCursor CURSOR FOR
SELECT CVE_ART, EXIST FROM MULT01 WHERE EXIST > 0 AND CVE_ALM = @ALMACENORIGEN AND CVE_ART IN(SELECT CVE_ART FROM MULT01 WHERE CVE_ALM = @ALMACENDESTINO)
OPEN TableCursor
FETCH NEXT FROM TraspasoCursor INTO @CURRENTPRODUCT, @CURRENTEXIST
WHILE @@FETCH_STATUS = 0
BEGIN
--ACTUALIZA EXISTENCIA EN MULTIALMACEN DEL ALMACEN DESTINO
PRINT('CURRENTPRODUCT: ' + @CURRENTPRODUCT)
PRINT('CURRENTEXIST: ' + CONVERT(VARCHAR,@CURRENTEXIST))
PRINT ('SELECT EXIST FROM MULT01 WHERE CVE_ART = '''+@CURRENTPRODUCT+''' AND CVE_ALM = '+CONVERT(VARCHAR,@ALMACENDESTINO)+'')
SET @PREVIOUSTEXIST = (SELECT EXIST FROM MULT01 WHERE CVE_ART = @CURRENTPRODUCT AND CVE_ALM = @ALMACENDESTINO)
SET @NEWEXIST = @PREVIOUSTEXIST + @CURRENTEXIST
PRINT('PREVIOUSTEXIST: ' + CONVERT(VARCHAR,@PREVIOUSTEXIST))
PRINT('NEWEXIST: ' + CONVERT(VARCHAR,@NEWEXIST))
PRINT('UPDATE MULT01 SET EXIST = ' + CONVERT(VARCHAR,@NEWEXIST) +' WHERE CVE_ART = '''+@CURRENTPRODUCT+''' AND CVE_ALM = '+CONVERT(VARCHAR,@ALMACENDESTINO)+'')
EXEC('UPDATE MULT01 SET EXIST = ' + @NEWEXIST +' WHERE CVE_ART = '''+@CURRENTPRODUCT+''' AND CVE_ALM = '+@ALMACENDESTINO+'')

--OBTIENE EXISTENCIA GLOBAL EN CATALOGO
SET @GLOBALEXIST = (SELECT SUM(EXIST) FROM MULT01 WHERE CVE_ART = @CURRENTPRODUCT)
PRINT('GLOBALEXIST: ' + CONVERT(VARCHAR,@GLOBALEXIST))

--INGRESA MOVIMIENTO AL INVENTARIO CON CONCEPTO 58
SET @LASTFOLIO = @LASTFOLIO + 1
SET @LASTNUMMOV = @LASTNUMMOV + 1
SET @COST = (SELECT ULT_COSTO FROM INVE01 WHERE CVE_ART = @CURRENTPRODUCT)
PRINT ('INSERT INTO MINVE01 VALUES ('''+@CURRENTPRODUCT+''','+CONVERT(VARCHAR,@ALMACENORIGEN)+','+CONVERT(VARCHAR,@LASTNUMMOV)+',58,GETDATE(),''M'',''CIERREMERCERIA'',NULL,NULL,'+CONVERT(VARCHAR,@CURRENTEXIST)+',0,0,'+CONVERT(VARCHAR,@COST)+',NULL,NULL,0,''pz'',0,'+CONVERT(VARCHAR,@GLOBALEXIST)+',0,''P'',1,GETDATE(),NULL,'+CONVERT(VARCHAR,@LASTFOLIO)+',-1,''S'','+CONVERT(VARCHAR,@COST)+','+CONVERT(VARCHAR,@COST)+','+CONVERT(VARCHAR,@COST)+',''S'',0)')
EXEC ('INSERT INTO MINVE01 VALUES ('''+@CURRENTPRODUCT+''','+@ALMACENORIGEN+','+@LASTNUMMOV+',58,GETDATE(),''M'',''CIERREMERCERIA'',NULL,NULL,'+@CURRENTEXIST+',0,0,'+@COST+',NULL,NULL,0,''pz'',0,'+@GLOBALEXIST+',0,''P'',1,GETDATE(),NULL,'+@LASTFOLIO+',-1,''S'','+@COST+','+@COST+','+@COST+',''S'',0)')

--INGRESA MOVIMIENTO AL INVENTARIO CON CONCEPTO 7
SET @PREVIOUSTNUMMOV = @LASTNUMMOV
SET @LASTFOLIO = @LASTFOLIO + 1
SET @LASTNUMMOV = @LASTNUMMOV + 1
SET @COST = (SELECT ULT_COSTO FROM INVE01 WHERE CVE_ART = @CURRENTPRODUCT)
PRINT ('INSERT INTO MINVE01 VALUES ('''+@CURRENTPRODUCT+''','+CONVERT(VARCHAR,@ALMACENDESTINO)+','+CONVERT(VARCHAR,@LASTNUMMOV)+',7,GETDATE(),''M'',''CIERREMERCERIA'',NULL,NULL,'+CONVERT(VARCHAR,@CURRENTEXIST)+',0,0,'+CONVERT(VARCHAR,@COST)+',NULL,NULL,0,''pz'',0,'+CONVERT(VARCHAR,@GLOBALEXIST)+','+CONVERT(VARCHAR,@NEWEXIST)+',''P'',1,GETDATE(),NULL,'+CONVERT(VARCHAR,@LASTFOLIO)+',1,''S'','+CONVERT(VARCHAR,@COST)+','+CONVERT(VARCHAR,@COST)+','+CONVERT(VARCHAR,@COST)+',''S'','+CONVERT(VARCHAR,@PREVIOUSTNUMMOV)+')')
EXEC ('INSERT INTO MINVE01 VALUES ('''+@CURRENTPRODUCT+''','+@ALMACENDESTINO+','+@LASTNUMMOV+',7,GETDATE(),''M'',''CIERREMERCERIA'',NULL,NULL,'+@CURRENTEXIST+',0,0,'+@COST+',NULL,NULL,0,''pz'',0,'+@GLOBALEXIST+','+@NEWEXIST+',''P'',1,GETDATE(),NULL,'+@LASTFOLIO+',1,''S'','+@COST+','+@COST+','+@COST+',''S'','+@PREVIOUSTNUMMOV+')')

--ACTUALIZA EXISTENCIA EN MULTIALMACEN DEL ALMACEN ORIGEN
PRINT('UPDATE MULT01 SET EXIST = 0 WHERE CVE_ART = '''+@CURRENTPRODUCT+''' AND CVE_ALM = '+CONVERT(VARCHAR,@ALMACENORIGEN)+'')
EXEC('UPDATE MULT01 SET EXIST = 0 WHERE CVE_ART = '''+@CURRENTPRODUCT+''' AND CVE_ALM = '+@ALMACENORIGEN+'')

FETCH NEXT FROM TraspasoCursor INTO @CURRENTPRODUCT, @CURRENTEXIST
END
CLOSE TraspasoCursor
DEALLOCATE TraspasoCursor

--SE ACTUALIZAN LOS VALORES EN LA TABLA DE CONTROL
UPDATE TBLCONTROL01 SET ULT_CVE = @LASTNUMMOV WHERE ID_TABLA = 44
UPDATE TBLCONTROL01 SET ULT_CVE = @LASTFOLIO WHERE ID_TABLA = 32


--ESTO ES OPCIONAL, SE CAMBIA EL STATUS A BAJA AL ALMACEN ORIGEN
UPDATE ALMACENES01 SET [STATUS] = 'B' WHERE CVE_ALM = @ALMACENORIGEN
