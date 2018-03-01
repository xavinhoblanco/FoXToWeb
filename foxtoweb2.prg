DEFINE CLASS FoxToWeb_library AS custom 
	
	*** Iniciar la Libreria
	PROCEDURE init

	ENDPROC


	**** Se guardan los parametros para realizar la conexion.
	**** Se mira si existe la table y si no existe la creamos
	**** para guardar los datos de conexion
	PROCEDURE Configurar
		LOCAL seguir 
		
		DO FORM pant\configuracion TO seguir
		
		RETURN seguir 
		
	ENDPROC
	
	PROCEDURE test_conexion
		LPARAMETERS ip_MySQL,usu_MySQL,PWD_MySQL,db_MySQL,port_MySQL


		lcStringCnxLocal = "DRIVER={MYSQL ODBC 5.3 ANSI Driver};" +;
		"SERVER=" + ALLTRIM(ip_MySQL)+";" +;
		"UID="+ALLTRIM(usu_MySQL)+";" +;
		"PWD="+alltrim(pwd_MySQL)+";"+;
		"DATABASE="+alltrim(db_MySQL)+";" +;
		"port="+alltrim(port_MySQL)+";"



		

		SQLSETPROP(0,"DispLogin" , 3 )

		lnHandle = SQLSTRINGCONNECT(lcStringCnxLocal)

		
		
		RETURN lnHandle
		
	
	PROCEDURE conectar
		LOCAL ip_MySQL,usu_MySQL,PWD_MySQL,db_MySQL,port_MySQL

		IF !file("datos\conexion.dbf") &&& No se existe tabla conexion cogemos datos genericos para prueba 
			*variables de conexion 1
			ip_MySQL = "127.0.0.1"
			usu_MySQL = "root"
			PWD_MySQL = "root"
			db_MySQL  = ""
			port_MySQL = "3306"
		ELSE
			
			IF !USED("conexion")
				USE datos\conexion IN 0
			ENDIF
			
			SELECT conexion
			ip_MySQL = ALLTRIM(conexion.server)
			usu_MySQL = ALLTRIM(conexion.usuario)
			PWD_MySQL = ALLTRIM(conexion.password)
			db_MySQL  = ALLTRIM(conexion.base)
			port_MySQL = ALLTRIM(conexion.puerto)
			
			SELECT conexion
			USE
			
		endif



		lcStringCnxLocal = "DRIVER={MYSQL ODBC 5.3 ANSI Driver};" +;
		"SERVER=" + ALLTRIM(ip_MySQL)+";" +;
		"UID="+ALLTRIM(usu_MySQL)+";" +;
		"PWD="+alltrim(pwd_MySQL)+";"+;
		"DATABASE="+alltrim(db_MySQL)+";" +;
		"port="+alltrim(port_MySQL)+";"


		SQLSETPROP(0,"DispLogin" , 3 )

		lnHandle = SQLSTRINGCONNECT(lcStringCnxLocal)

		this.mensaje(lnhandle,"CONECTAR")
		
		RETURN lnHandle
	ENDPROC
	
	PROCEDURE desconexion
		LPARAMETERS  lnhandle
		LOCAL cmd
		
		cmd = SQLDISCONNECT(lnhandle)
		
		this.mensaje(CMD,"DESCONECTAR")
		
	ENDPROC
	
	PROCEDURE mensaje

	LPARAMETERS cmd, operacion
	
		IF cmd>0
			WAIT WINDOW "La operacion: " + UPPER(operacion) + " se ha realizado con exito" NOWAIT 
		ELSE
			WAIT WINDOW "La operacion: " + UPPER(operacion) + " no se ha realizado" NOWAIT 
		ENDIF
	
	ENDPROC
	
	PROCEDURE leer_bd_VFP
		LOCAL archivodbc, nombdbc, lnhandle,cmd,dirbases, comandoSQL, paso
		

		
		paso = .f.
		
		paso = this.configurar()
		
		DO while !paso
		ENDDO
		**** Selecciono el fichero .dbc de la base de datos
		archivodbc= GETFILE("dbc","Archivo .DBC:","Seleccionar",0,"Seleccione la base de datos a exportar:")
		

		IF !EMPTY(archivodbc)
			
		** Compruebo que es un archivo .dbc
			IF !(LOWER(SUBSTRC(archivodbc,ATC(".",archivodbc,OCCURS(".",archivodbc))+1,3))=="dbc")
				MESSAGEBOX("El fichero seleccionado no es un contenedor valido de base de datos",0,"FoxToWeb")
			ELSE

				&&&nombre de la base de datos a crear
				nombdbc = LOWER(SUBSTRC(archivodbc,ATC("\",archivodbc,OCCURS("\",archivodbc))+1))
				lnhandle=this.conectar()
				IF lnhandle >0
					&&& Quitamos la extension del contenedor de base de datos
					newbd =SUBSTRC(ALLTRIM(nombdbc),1,ATC(".",ALLTRIM(nombdbc),OCCURS(".",ALLTRIM(nombdbc)))-1)
					
					cmd=SQLEXEC(lnhandle,"CREATE DATABASE " + newbd +" DEFAULT CHARACTER SET utf8 COLLATE utf8_spanish_ci")
					this.mensaje(cmd,"Crear base de datos en MySQL")
					IF cmd >0
						SQLEXEC(lnhandle,"USE " + newbd)
					ENDIF  
					CLOSE DATABASES ALL &&&
					USE &archivodbc ALIAS bd IN 0
					&&& Selecciono el nombre de las tablas del dbc 
					SELECT objectname as nombtabla, .t. as incluir FROM bd WHERE objecttype="Table" INTO CURSOR nombretablas ORDER BY 1 READWRITE 
					
					SELECT bd
					USE
					&&& Ahora creamos las tablas dentro de la base de datos ya creada.

					DO FORM pant\tablas
					
					*** Cojo el directorio en el que está guardado
					dirbases = LOWER(SUBSTRC(archivodbc,1,ATC("\",archivodbc,OCCURS("\",archivodbc))))
					SELECT nombretablas
					GO top
					SCAN FOR nombrebretablas.incluir
						comandoSQL = ""
						IF !USED(ALLTRIM(nombretablas.nombtabla))
							USE ALLTRIM(dirbases+ALLTRIM(nombretablas.nombtabla)) IN 0
						ENDIF
						SELECT ALLTRIM(nombretablas.nombtabla)
						newnombtabla = ALLTRIM(nombretablas.nombtabla)
						&&&Creo la tabla
						comandoSQL = comandoSQL +"CREATE TABLE " + newnombtabla +"("
						&&& meto todos los campos un autoincremental
						comandoSQL = comandoSQL + " id"+newnombtabla +" INTEGER NOT NULL AUTO_INCREMENT,"
						&&& campos insert será para ir rellenado nombres de campos a insertar
						
						camposinsert =""
						&&& Meto los valores a insertar
						
						camposvalue =""
						ncampos = AFIELDS(campos)
						FOR i = 1 TO ncampos
							***nombre del campo
							nuevocampo = campos(i,1)
							comandoSQl = comandoSQL +  nuevocampo

							*** voy rellenando con los campos
 							camposinsert = camposinsert + nuevocampo + ","
							camposvalue =  camposvalue +"?"+newnombtabla+"."+campos(i,1)+","
							
							newtipo = this.tipos(campos(i,2))
							IF !(newtipo = "DATE")
								comandoSQl = comandoSQL + " "+newtipo +"("
								tamtipo = ALLTRIM(STR(campos(i,3)))
								comandoSQl = comandoSQL + tamtipo
								
								IF campos(i,4) > 0
									comandoSQl = comandoSQL + ","+ ALLTRIM(STR(campos(i,4)))
								ENDIF
							ELSE
								&&& Los tipo date no llevan tamaño
								comandoSQl = comandoSQL + " "+newtipo
							ENDIF
*!*								IF newtipo = "DATE"
*!*									comandoSQl = comandoSQL +  " NULL,"
*!*								ELSE
*!*									comandoSQl = comandoSQL +  ") NULL," 
*!*								ENDIF
						IF !(newtipo = "DATE")
							IF campos(i,5)=.f. 
								comandoSQl = comandoSQL + ") NOT NULL,"
							ELSE
								comandoSQl = comandoSQL + ") NULL,"
							ENDIF	
						ELSE
							IF campos(i,5)=.f. 
								comandoSQl = comandoSQL + " NOT NULL,"
							ELSE
								comandoSQl = comandoSQL + " NULL,"
							ENDIF										
						ENDIF
						
						ENDFOR
						&& saco la coma del ultimo campo
						comandoSQL = SUBSTRC(ALLTRIM(comandoSQL),1,LEN(ALLTRIM(comandoSQL))-1)
						
						camposinsert = SUBSTRC(ALLTRIM(camposinsert),1,LEN(ALLTRIM(camposinsert))-1)
						camposvalue = SUBSTRC(ALLTRIM(camposvalue),1,LEN(ALLTRIM(camposvalue))-1)
						
						
						&& Añado ; final
						SQLEXEC(lnhandle,"USE " +newbd)
						comandoSQL = comandoSQL + ", PRIMARY KEY (" + "id" + newnombtabla + ")) DEFAULT CHARACTER SET = utf8 COLLATE = utf8_spanish_ci"			
	
						
						
						cmd = SQLEXEC(lnhandle,comandoSQL)
						this.mensaje(cmd,"CREACION TABLA: "+newnombtabla)

					
															
						comandoSQL2 = "INSERT INTO " + newnombtabla + "(" + camposinsert + ")" + "VALUES (" + camposvalue + ")" 
						
				
						SELECT &newnombtabla
						GO top
						numreg  =1 
						SCAN 
							cmd = SQLEXEC(lnhandle,comandoSQl2)	
					
							this.mensaje(cmd , "INSERTANDO REG." + ALLTRIM(STR(numreg)) + " EN TABLA: " +newnombtabla)
							
							numreg = numreg + 1
						ENDSCAN
						

						SELECT &newnombtabla
						use		
						
								
					ENDSCAN 
									
				ENDIF
				
				this.desconexion(lnhandle)
				
				SELECT nombretablas
				use
			ENDIF
		ENDIF 
	ENDPROC
	
	PROCEDURE nombredbc
		LPARAMETERS tablaopen

		
		SELECT &tablaopen
		nombdbc=SUBSTRC(ALLTRIM(CURSORGETPROP("Database")),ATC("\",ALLTRIM(CURSORGETPROP("Database")),OCCURS("\",ALLTRIM(CURSORGETPROP("Database"))))+1,ATC(".",ALLTRIM(CURSORGETPROP("Database")))-ATC("\",ALLTRIM(CURSORGETPROP("Database")),OCCURS("\",ALLTRIM(CURSORGETPROP("Database"))))-1)

		RETURN nombdbc
				
	endproc
	
	PROCEDURE insertar
		LPARAMETERS tablaact
		local cmdinsert, nombinsert2, nombdbc, i, lnhandle

		nombdbc = this.nombredbc(tablaact)
		SELECT &tablaact
		ncampos = AFIELDS(campos)
		cmdinsert  ="INSERT INTO "+ nombdbc + "." + tablaact + "("
		cmdinsert2 = ""
		FOR i = 1 TO ncampos
			cmdinsert= cmdinsert + ALLTRIM(campos(i,1)) + ","
			cmdinsert2 = cmdinsert2 + "?" + tablaact + "." + ALLTRIM(campos(i,1)) +","

				
		ENDFOR		
		
		&&& elimino la , final y añado un )
		cmdinsert =ALLTRIM(SUBSTRC(ALLTRIM(cmdinsert),1,LEN(ALLTRIM(cmdinsert))-1))+")"
		cmdinsert2 =ALLTRIM(SUBSTRC(ALLTRIM(cmdinsert2),1,LEN(ALLTRIM(cmdinsert2))-1))+")"

		CmdSQLins  =cmdinsert + "values(" + cmdinsert2 
		
		lnhandle = this.conectar()
		IF lnhandle > 0
			cmd = SQLEXEC(lnhandle,cmdSQLins)
			this.mensaje(cmd,"INSERTAR REGISTRO EN TABLA: " +ALLTRIM(tablaact))
		ENDIF
		this.desconexion(lnhandle)
		
	ENDPROC
	
	PROCEDURE borrar
		LPARAMETERS tablaact
		LOCAL nindices, expindice, cmdSQLDel, nombdbc, lnhandle
		
		nombdbc = this.nombredbc(tablaact)
		&&& Tenemos que saber la clave de la tabla y su valor para borrar ese registro
		SELECT &tablaact
		&& obtengo indice
		nindices = ATAGINFO(indices)
		
		IF nindices >0
			expindice = indices(1,3)
		ELSE
			expindice =""
		ENDIF
		
		cmdSQLDel = "DELETE FROM " + nombdbc + "." + tablaact +" WHERE " + tablaact + "." + expindice + " = " + "?" + tablaact + "." + expindice

		lnhandle = this.conectar()
		IF lnhandle > 0
			cmd = SQLEXEC(lnhandle,cmdSQLDel)
			this.mensaje(cmd,"BORRAR REGISTRO EN TABLA: " +ALLTRIM(tablaact))
		ENDIF
		this.desconexion(lnhandle)
	
	ENDPROC
	
	PROCEDURE modificar
		LPARAMETERS tablaact
		LOCAL nombdbc, ninidices, ncamposm, camposact,cambios,cmdsql,clave,campoweb, campoloc
		
		nombdbc = this.nombredbc(tablaact)
		SELECT &tablaact
		&& obtengo indice
		nindices = ATAGINFO(indices)
		IF nindices>0
			expindice = indices(1,3)
		ELSE
			expindice=""
		endif		
		clave =tablaact +"."+ indices(1,3)
		clave = &clave
		
		SELECT &tablaact
		ncamposm = AFIELDS(camposm)
		
		camposact = ""
		
		IF cursorgetprop('Buffering') = 5 &&& tiene activado el buffermode sabemos que campo está cambiado
			cambios = SUBSTRC(getfldstate(-1),2)
			IF OCCURS("2",cambios) > 0 &&& hay al memos un cambio
				FOR i = 1 TO OCCURS("2",cambios)
					IF ATC("2",ALLTRIM(cambios),i)>0 &&& la posicion del 2 indica el campo editado
						camposact = camposact + tablaact + "." + ALLTRIM(camposm(ATC("2",ALLTRIM(cambios),i),1)) + "=" + "?" + tablaact + "." + ALLTRIM(camposm(ATC("2",ALLTRIM(cambios),i),1)) +"," 
					ENDIF
				ENDFOR
				 
				&&&Quito la coma final				
*				camposact = ALLTRIM(SUBSTRC(ALLTRIM(camposact),1,LEN(ALLTRIM(camposact))-1))
				
				cond = " WHERE " + tablaact + "." + expindice + " = " + "?" + tablaact + "." + expindice 
				
*				cmdsql = "UPDATE " + nombdbc + "." + tablaact + "SET " + camposact + cond
			ENDIF 
		ELSE

			&&& si no está habilitado el buffermode tengo que comparar todos los campos
			IF !EMPTY(expindice)
			
				cond = " WHERE " + tablaact + "." + expindice + " = " + "?" + tablaact+"."+expindice
			ELSE
				cond = ""
			ENDIF
			IF !EMPTY(cond) &&& No se puede actualizar al no tener indice
				cursorweb = this.consulta(tablaact,cond)	

				regweb = RECCOUNT("cursorweb")
				
				IF !(regweb > 0) &&& Este registro no está subido a la web no se puede actualizar
					this.insertar(tablaact)
				ELSE
										
					&& comparo los campos uno a uno par saber cual se ha modificado
					&& cursor WEB será campo(i+1,1) porque en la creacion le hemos creado un campo autonumerico
					&& en primer lugar
					If USED("cursorweb")
						SELECT cursorweb
						nfieldweb = AFIELDS(ncamposweb)
						SELECT &tablaact
						FOR i=1 TO ncamposm
							
							campoweb = 	"cursorweb."+ncamposweb(i+1,1) &&& cojo el campo que corresponde
							campoweb=&campoweb &&& cargo el valor del campo
							campoloc = tablaact +"." + camposm(i,1)
							campoloc = &campoloc
							IF !(campoweb=IIF(VARTYPE(campoloc)="L",IIF(campoloc=.t.,1,0),campoloc))
								camposact = camposact + tablaact + "." + ncamposweb(i+1,1) + "=" + "?" + tablaact + "." + camposm(i,1) +"," 
							ENDIF
						ENDFOR

						cond = " WHERE " + tablaact + ".id" + tablaact + " = " + "?cursorweb.id" + tablaact
					endif
				ENDIF
			ELSE
				
			ENDIF
		endif
 
		&&&Quito la coma final				
		camposact = ALLTRIM(SUBSTRC(ALLTRIM(camposact),1,LEN(ALLTRIM(camposact))-1))	
		cmdsql = "UPDATE " + nombdbc + "." + tablaact + " SET " + camposact + cond					
									

		IF EMPTY(camposact) OR EMPTY(cond) &&& NO se ha detectado ningun cambio
				
		ELSE
			&&& lanzo la modificacion
			lnhandle = this.conectar()
			
			IF lnhandle > 0 	
				cmd = SQLEXEC(lnhandle,cmdsql)
				this.mensaje(cmd, " Actualizar registro tabla: " + tablaact)
				this.desconexion(lnhandle)
			ENDIF
			
			IF USED("cursorweb")
				SELECT cursorweb
				USE
			ENDIF
		endif
		SELECT &tablaact &&& dejo activa la misma tabla que al entrar				
						
	ENDPROC
	

	PROCEDURE consulta
		LPARAMETERS tablaact, cond 
		LOCAL cmdsql, nombdbc, cursorweb,lnhandle


		
		cursorweb =""
		
		nombdbc = this.nombredbc(tablaact)
		
		cmdsql = "SELECT * FROM " + nombdbc +"."+tablaact +IIF(!EMPTY(ALLTRIM(cond)), cond ,"")
		
		lnhandle = this.conectar()
		
		IF lnhandle >0
			cmd = SQLEXEC(lnhandle,cmdsql,"cursorweb")
			
			this.desconexion(lnhandle)
		endif
		
		RETURN cursorweb
			
	ENDPROC
	
	PROCEDURE tipos
		LPARAMETERS tipovfp
		LOCAL tipoSQL 
		
		DO CASE 
			CASE tipovfp = "C"
				tipoSQL ="VARCHAR"

			CASE tipovfp = "I" 
				tipoSQL = "INTEGER"

			CASE tipovfp = "N"
				tipoSQL = "DECIMAL"
			
			CASE tipovfp = "D" 
				tipoSQL = "DATE"
			
			CASE tipovfp = "M"
				tipoSQL = "TEXT"
				
			CASE tipovfp = "L"
				tipoSQL = "TINYINT"
				
			CASE tipovfp = "T"
				tipoSQL = "DATETIME"
			
			CASE tipovfp = "F"
				tipoSQL = "FLOAT"
				
			CASE tipovfp = "G"
				tipoSQL = "GENERAL"
			
			CASE tipovfp = "F"
				tipoSQL = "FLOAT"

			CASE tipovfp = "B"
				tipoSQL = "DOUBLE"
				
			CASE tipovfp = "Y"
				tipoSQL = "YEAR"
			
			CASE tipovfp = "w"
				tipoSQL = "BLOB"
				
			OTHERWISE
				tipovfp = "TEXT"
																		
		ENDCASE
		
		RETURN tipoSQL
		
	ENDPROC
	
	
	
ENDDEFINE 