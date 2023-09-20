#include "protheus.ch"

//-------------------------------------------------------------------
/*/{Protheus.doc} GERAXNU()
Função que Veriica transforma o Menu no banco do Protheus em um arquivo XNU
@type  function
@author Roberta Soares
@site https://www.linkedin.com/in/roberta-soares-dos-santos-alves-73883035/
@since 18/09/2023
@version 1.0
/*/
//-------------------------------------------------------------------
User FuncTion GERAXNU()

	Local aParamBox := {}
	Local aRet      := {}
	Local cNomeMenu := Space(149)

	aAdd(aParamBox,{1,"Informe o Nome de Menu",cNomeMenu,"","","","",100,.T.})

	If ParamBox(aParamBox,"Conveter Menu em XNU ",@aRet)
		cNomeMenu := Alltrim(aRet[1])
		Processa({||GeraArq(cNomeMenu)},"Aguarde... Gerando Arquivo...")
	Endif

Return

//-------------------------------------------------------------------
/*/{Protheus.doc} GeraArq()
Gera o arquivo XNU de acordo com o menu informado
@type  function
@author Roberta Soares
@site https://www.linkedin.com/in/roberta-soares-dos-santos-alves-73883035/
@since 18/09/2023
@version 1.0
/*/
//-------------------------------------------------------------------
Static Function GeraArq(cNomeMenu)
	Local aMenu     := {}
	Local aPastas   := {}
	Local aSeqMenu  := {}
	Local cAliasTrb := GetNextAlias()
	Local cIDMenu   := ""
	Local cLocalSav := tFileDialog("*.*|*.*","Salvar em...",0, ,.F.,GETF_RETDIRECTORY)
	Local cMenu     := CRLF
	Local cModulo   := ""
	Local cQuery    := ""
	Local cStatus   := ""
	Local cTab      := "	"
	Local nA        := 0
	Local nEspaco   := 0
	Local nJ        := 0
	Local nT        := 0

	cQuery += "SELECT DISTINCT N_DESC,I_ID,I_FATHER,USR_CODMOD,I_ORDER,M_ID "+CRLF
	cQuery += "FROM   MPMENU_MENU"+CRLF
	cQuery += "       INNER JOIN MPMENU_ITEM ITEM_MENU"+CRLF
	cQuery += "               ON M_ID = I_ID_MENU"+CRLF
	cQuery += "	   INNER JOIN SYS_USR_MODULE MODULOS"+CRLF
	cQuery += "           ON USR_MODULO = M_MODULE"+CRLF
	cQuery += "		      AND MODULOS.D_E_L_E_T_ = ' '"+CRLF
	cQuery += "       INNER JOIN MPMENU_I18N DESCRICAO"+CRLF
	cQuery += "               ON DESCRICAO.D_E_L_E_T_ = ''"+CRLF
	cQuery += "                  AND DESCRICAO.N_PAREN_ID = ITEM_MENU.I_ID"+CRLF
	cQuery += "                  AND DESCRICAO.N_LANG = '1'"+CRLF
	cQuery += "                  AND DESCRICAO.D_E_L_E_T_ = ' '"+CRLF
	cQuery += "       LEFT JOIN MPMENU_FUNCTION FUNCOES"+CRLF
	cQuery += "              ON FUNCOES.D_E_L_E_T_ = ''"+CRLF
	cQuery += "                 AND FUNCOES.F_ID = ITEM_MENU.I_ID_FUNC"+CRLF
	cQuery += "                 AND FUNCOES.D_E_L_E_T_ = ' '"+CRLF
	cQuery += "WHERE  MPMENU_MENU.D_E_L_E_T_ = ''"+CRLF
	cQuery += "       AND M_NAME = '"+cNomeMenu+"'"+CRLF
	cQuery += "       AND I_FATHER = M_ID "+CRLF
	cQuery += "ORDER  BY I_ORDER  "+CRLF

	dbUseArea(.T.,"TOPCONN",TCGenQry(,,cQuery),cAliasTrb,.F.,.T.)

	While (cAliasTrb)->(!EOF())
		cModulo := (cAliasTrb)->USR_CODMOD
		cIDMenu := (cAliasTrb)->M_ID
		AADD(aPastas,(cAliasTrb)->I_ID)
		(cAliasTrb)->(DbSkip())
	EndDo

	(cAliasTrb)->(DbCloseArea())

	aSeqMenu := {}
	PastasMenu(cIDMenu,cIDMenu,@aSeqMenu,@aMenu)

	cMenu := '<ApMenu>'+CRLF
	cMenu += '	<DocumentProperties>'+CRLF
	cMenu += '		<Module>'+cModulo+'</Module>'+CRLF
	cMenu += '		<Version>10.1</Version>'+CRLF
	cMenu += '	</DocumentProperties>'+CRLF
	nEspaco += 1

	ProcRegua(Len(aMenu))

	cPastUsada := ""
	aPastUsada := {}
	lPrimLeit := .T.
	For nJ := 1 To Len(aMenu)

		IncProc()

		For nA := 1 To Len(aMenu[nJ])

			If nA < Len(aMenu[nJ]) //Se não é o utimo item do array então é uma pasta

				If !lPrimLeit //Se não for a primeia vez q ele passa

					lPastPrincipal := aMenu[nJ,nA,3] == cIDMenu

					If Len(aPastUsada) >= nA
						If aMenu[nJ,nA,2]+"|"+cValToChar(nA) <> aPastUsada[nA]//Se é uma nova "pasta" ele "fecha" as pastas anteriores
							nEspaco -= 1
							cMenu += Replicate(cTab,nEspaco)+'</Menu>'+CRLF
							ApgDadoArray(@aPastUsada,aPastUsada[Len(aPastUsada)])
						EndIf
					EndIf

					If lPastPrincipal
						//Se for uma pasta principal nova ele fecha as pastas anteriores
						If aMenu[nJ,nA,2]+"|"+cValToChar(nA) <> aPastUsada[nA]
							For nT := 1 To Len(aPastUsada)
								nEspaco -= 1
								cMenu += Replicate(cTab,nEspaco)+'</Menu>'+CRLF
								ApgDadoArray(@aPastUsada,aPastUsada[1])
							Next nT
						Endif
					EndIf

				Endif

				lPrimLeit := .F.

				If ASCAN(aPastUsada,aMenu[nJ,nA,2]+"|"+cValToChar(nA)) == 0 //Verifica se a pasta já foi "aberta"

					aDesc := DescMenu(aMenu[nJ,nA,3],aMenu[nJ,nA,2]) //Tras as descrições das pastas em pt , en, es
					AADD(aPastUsada,aMenu[nJ,nA,2]+"|"+cValToChar(nA)) //Id da pasta + Nivel

					//Grava no Menu a pasta
					cMenu += Replicate(cTab,nEspaco)+'<Menu Status="Enable">'+CRLF
					nEspaco += 1 //Usado para identação
					cMenu += Replicate(cTab,nEspaco)+'<Title lang="pt">'+aDesc[1]+'</Title>'+CRLF
					cMenu += Replicate(cTab,nEspaco)+'<Title lang="es">'+aDesc[2]+'</Title>'+CRLF
					cMenu += Replicate(cTab,nEspaco)+'<Title lang="en">'+aDesc[3]+'</Title>'+CRLF

				EndIf

			else
				aItem := InfoFunction(aMenu[nJ,nA,2],cIDMenu)

				If Len(aItem)

					If aItem[16] == "1"
						cStatus := "Enable"
					ElseIf aItem[16] == "2"
						cStatus := "Disabled"
					ElseIf aItem[16] == "3"
						cStatus := "Hiden"
					EndIf

					cMenu += Replicate(cTab,nEspaco)+'<MenuItem Status="'+cStatus+'">'+CRLF
					nEspaco += 1
					cMenu += Replicate(cTab,nEspaco)+'<Title lang="pt">'+aItem[2]+'</Title>'+CRLF
					cMenu += Replicate(cTab,nEspaco)+'<Title lang="es">'+aItem[3]+'</Title>'+CRLF
					cMenu += Replicate(cTab,nEspaco)+'<Title lang="en">'+aItem[4]+'</Title>'+CRLF
					cMenu += Replicate(cTab,nEspaco)+'<Function>'+aItem[5]+'</Function>'+CRLF
					cMenu += Replicate(cTab,nEspaco)+'<Type>'+aItem[14]+'</Type>'+CRLF

					aTables := Separa(aItem[7],";",.F.)
					For nT := 1 To Len(aTables)
						cMenu += Replicate(cTab,nEspaco)+'<Tables>'+aTables[nT]+'</Tables>'+CRLF
					Next nT

					cMenu += Replicate(cTab,nEspaco)+'<Access>'+aItem[8]+'</Access>'+CRLF
					cMenu += Replicate(cTab,nEspaco)+'<Module>'+aItem[15]+'</Module>'+CRLF
					cMenu += Replicate(cTab,nEspaco)+'<Owner>'+aItem[10]+'</Owner>'+CRLF
					cMenu += Replicate(cTab,nEspaco)+'<KeyWord>'+CRLF
					nEspaco += 1
					cMenu += Replicate(cTab,nEspaco)+'<KeyWord lang="pt"></KeyWord>'+CRLF
					cMenu += Replicate(cTab,nEspaco)+'<KeyWord lang="es"></KeyWord>'+CRLF
					cMenu += Replicate(cTab,nEspaco)+'<KeyWord lang="en"></KeyWord>'+CRLF
					nEspaco -= 1
					cMenu += Replicate(cTab,nEspaco)+'</KeyWord>'+CRLF
					nEspaco -= 1
					cMenu += Replicate(cTab,nEspaco)+'</MenuItem>'+CRLF
				EndIf

			EndIf

		Next nA
	Next nJ

	For nT := 1 To Len(aPastUsada)
		nEspaco -= 1
		cMenu += Replicate(cTab,nEspaco)+'</Menu>'+CRLF
		ApgDadoArray(@aPastUsada,aPastUsada[1])
	Next nT

	cMenu += '</ApMenu>'

	nHandle := MsfCreate(cLocalSav+"\"+cNomeMenu+".xnu",0)
	fWrite(nHandle, cMenu )
	fClose(nHandle)

Return

//-------------------------------------------------------------------
/*/{Protheus.doc} ApgDadoArray()
Remove o Dado do array
@type  function
@author Roberta Soares
@site https://www.linkedin.com/in/roberta-soares-dos-santos-alves-73883035/
@since 18/09/2023
@version 1.0
/*/
//-------------------------------------------------------------------
Static Function ApgDadoArray(aInfo,cBusc)
	Local nI := 1
	Local aNovoArray := {}

	For nI := 1 To Len(aInfo)
		If aInfo[nI] <> cBusc
			AADD(aNovoArray,aInfo[nI])
		EndIf
	Next nI

	aInfo := aNovoArray

Return

//-------------------------------------------------------------------
/*/{Protheus.doc} PastasMenu()
Grava as pastas do menu até chegar na função 
@type  function
@author Roberta Soares
@site https://www.linkedin.com/in/roberta-soares-dos-santos-alves-73883035/
@since 18/09/2023
@version 1.0
/*/
//-------------------------------------------------------------------
Static Function PastasMenu(cIDMenu,cId,aSeqMenu,aMenu)
	Local cAliasTrb := GetNextAlias()
	Local cQuery    := ""
	Local nI := 0
	Local aAux := {}

	cQuery += "SELECT N_DESC,I_ID,I_FATHER"+CRLF
	cQuery += "FROM MPMENU_MENU INNER JOIN MPMENU_ITEM ITEM_MENU ON M_ID = I_ID_MENU"+CRLF
	cQuery += "INNER JOIN MPMENU_I18N DESCRICAO ON DESCRICAO.D_E_L_E_T_ = '' AND DESCRICAO.N_PAREN_ID = ITEM_MENU.I_ID AND DESCRICAO.N_LANG = '1' AND DESCRICAO.D_E_L_E_T_ = ' '"+CRLF
	cQuery += "LEFT JOIN MPMENU_FUNCTION FUNCOES ON FUNCOES.D_E_L_E_T_ = '' AND  FUNCOES.F_ID = ITEM_MENU.I_ID_FUNC AND FUNCOES.D_E_L_E_T_ = ' '"+CRLF
	cQuery += "WHERE MPMENU_MENU.D_E_L_E_T_ = ''"+CRLF
	cQuery += "AND M_ID = '"+cIDMenu+"'"+CRLF
	cQuery += "AND I_FATHER = '"+cId+"'"+CRLF
	cQuery += "ORDER BY I_ORDER"+CRLF

	dbUseArea(.T.,"TOPCONN",TCGenQry(,,cQuery),cAliasTrb,.F.,.T.)

	If (cAliasTrb)->(EOF())
		AADD(aMenu,aSeqMenu)
		aAux := {}
		For nI := 1 To Len(aSeqMenu)-1
			AADD(aAux,aSeqMenu[nI])
		Next nI
		aSeqMenu := aAux
	EndIf

	While (cAliasTrb)->(!EOF())
		If (cAliasTrb)->I_FATHER == cIDMenu
			aSeqMenu := {}
		EndIf
		AADD(aSeqMenu,{(cAliasTrb)->N_DESC,(cAliasTrb)->I_ID,(cAliasTrb)->I_FATHER,Len(aSeqMenu)+1})
		PastasMenu(cIDMenu,(cAliasTrb)->I_ID,@aSeqMenu,@aMenu)
		(cAliasTrb)->(DbSkip())
	EndDo

	(cAliasTrb)->(DbCloseArea())

Return

//-------------------------------------------------------------------
/*/{Protheus.doc} DescMenu()
Busca a descrição da Pasta em diferentes linguagens
@type  function
@author Roberta Soares
@site https://www.linkedin.com/in/roberta-soares-dos-santos-alves-73883035/
@since 18/09/2023
@version 1.0
/*/
//-------------------------------------------------------------------
Static Function DescMenu(cIDMenu,cId)
	Local cAliasTrb := GetNextAlias()
	Local cQuery    := ""
	Local aRet      := {}

	cQuery += "SELECT DESCRICAO.N_DESC DESC_PT, DESCRICAO2.N_DESC DESC_ES, DESCRICAO3.N_DESC DESC_EN"+CRLF
	cQuery += "FROM MPMENU_MENU INNER JOIN MPMENU_ITEM ITEM_MENU ON M_ID = I_ID_MENU"+CRLF
	cQuery += "INNER JOIN MPMENU_I18N DESCRICAO ON DESCRICAO.D_E_L_E_T_ = '' AND DESCRICAO.N_PAREN_ID = ITEM_MENU.I_ID AND DESCRICAO.N_LANG = '1'"+CRLF
	cQuery += "INNER JOIN MPMENU_I18N DESCRICAO2 ON DESCRICAO2.D_E_L_E_T_ = '' AND DESCRICAO2.N_PAREN_ID = ITEM_MENU.I_ID AND DESCRICAO2.N_LANG = '2' "+CRLF
	cQuery += "INNER JOIN MPMENU_I18N DESCRICAO3 ON DESCRICAO3.D_E_L_E_T_ = '' AND DESCRICAO3.N_PAREN_ID = ITEM_MENU.I_ID AND DESCRICAO3.N_LANG = '3'"+CRLF
	cQuery += "LEFT JOIN MPMENU_FUNCTION FUNCOES ON FUNCOES.D_E_L_E_T_ = '' AND  FUNCOES.F_ID = ITEM_MENU.I_ID_FUNC AND FUNCOES.D_E_L_E_T_ = ' '"+CRLF
	cQuery += "WHERE MPMENU_MENU.D_E_L_E_T_ = ''"+CRLF
	cQuery += "AND I_ID = '"+cId+"'"+CRLF

	dbUseArea(.T.,"TOPCONN",TCGenQry(,,cQuery),cAliasTrb,.F.,.T.)

	If (cAliasTrb)->(!EOF())
		AADD(aRet,Alltrim(DESC_PT))
		AADD(aRet,Alltrim(DESC_ES))
		AADD(aRet,Alltrim(DESC_EN))
	EndIf

	(cAliasTrb)->(DbCloseArea())

Return aRet

//-------------------------------------------------------------------
/*/{Protheus.doc} InfoFunction()
Busca a informação da função para gravar no XNU
@type  function
@author Roberta Soares
@site https://www.linkedin.com/in/roberta-soares-dos-santos-alves-73883035/
@since 18/09/2023
@version 1.0
/*/
//-------------------------------------------------------------------
Static Function InfoFunction(cIDFunc,cIDMenu)
	Local cQuery := ""
	Local cAliasTrb := GetNextAlias()
	Local aRet := {}

	cQuery += "SELECT DISTINCT MENUS.M_ID MENU_ID,"+CRLF
	cQuery += "                DESCRICAO.N_DESC DESC_PT,"+CRLF
	cQuery += "                ISNULL(DESCRICAO3.N_DESC, DESCRICAO.N_DESC) DESC_ES,"+CRLF
	cQuery += "                ISNULL(DESCRICAO2.N_DESC, DESCRICAO.N_DESC) DESC_EN,"+CRLF
	cQuery += "                F_FUNCTION FUNCAO,"+CRLF
	cQuery += "                I_TYPE TIPO,"+CRLF
	cQuery += "                I_TABLES,"+CRLF
	cQuery += "                I_ACCESS ACESSO,"+CRLF
	cQuery += "                M_MODULE,"+CRLF
	cQuery += "                I_OWNER,"+CRLF
	cQuery += "                MODULOS.USR_CODMOD,"+CRLF
	cQuery += "                I_ID,"+CRLF
	cQuery += "                I_ORDER,"+CRLF
	cQuery += "                I_TYPE,"+CRLF
	cQuery += "                I_MODULE,"+CRLF
	cQuery += "                I_STATUS"+CRLF
	cQuery += "FROM   MPMENU_MENU MENUS"+CRLF
	cQuery += "       INNER JOIN MPMENU_ITEM ITEM_MENU"+CRLF
	cQuery += "               ON ITEM_MENU.D_E_L_E_T_ = ''"+CRLF
	cQuery += "                  AND MENUS.M_ID = ITEM_MENU.I_ID_MENU"+CRLF
	cQuery += "       INNER JOIN MPMENU_FUNCTION FUNCOES"+CRLF
	cQuery += "               ON FUNCOES.D_E_L_E_T_ = ''"+CRLF
	cQuery += "                  AND FUNCOES.F_ID = ITEM_MENU.I_ID_FUNC"+CRLF
	cQuery += "                  AND FUNCOES.D_E_L_E_T_ = ' '"+CRLF
	cQuery += "       INNER JOIN SYS_USR_MODULE MODULOS"+CRLF
	cQuery += "               ON MODULOS.D_E_L_E_T_ = ''"+CRLF
	cQuery += "                  AND USR_MODULO = M_MODULE"+CRLF
	cQuery += "       INNER JOIN MPMENU_I18N DESCRICAO"+CRLF
	cQuery += "               ON DESCRICAO.D_E_L_E_T_ = ''"+CRLF
	cQuery += "                  AND DESCRICAO.N_PAREN_ID = ITEM_MENU.I_ID"+CRLF
	cQuery += "                  AND DESCRICAO.N_LANG = '1'"+CRLF
	cQuery += "                  AND DESCRICAO.D_E_L_E_T_ = ' '"+CRLF
	cQuery += "       LEFT JOIN MPMENU_I18N DESCRICAO2"+CRLF
	cQuery += "              ON DESCRICAO2.D_E_L_E_T_ = ''"+CRLF
	cQuery += "                 AND DESCRICAO2.N_PAREN_ID = ITEM_MENU.I_ID"+CRLF
	cQuery += "                 AND DESCRICAO2.N_LANG = '2'"+CRLF
	cQuery += "                 AND DESCRICAO2.D_E_L_E_T_ = ' '"+CRLF
	cQuery += "       LEFT JOIN MPMENU_I18N DESCRICAO3"+CRLF
	cQuery += "              ON DESCRICAO3.D_E_L_E_T_ = ''"+CRLF
	cQuery += "                 AND DESCRICAO3.N_PAREN_ID = ITEM_MENU.I_ID"+CRLF
	cQuery += "                 AND DESCRICAO3.N_LANG = '3'"+CRLF
	cQuery += "                 AND DESCRICAO3.D_E_L_E_T_ = ' '"+CRLF
	cQuery += "WHERE  MENUS.D_E_L_E_T_ = ' '"+CRLF
	cQuery += "       AND MENUS.M_ID = '"+cIDMenu+"'"+CRLF
	cQuery += "       AND ITEM_MENU.I_ID = '"+cIDFunc+"'"+CRLF
	cQuery += "ORDER  BY M_MODULE,MENUS.M_ID,I_ORDER "+CRLF

	dbUseArea(.T.,"TOPCONN",TCGenQry(,,cQuery),cAliasTrb,.F.,.T.)

	If (cAliasTrb)->(!EOF())

		AADD(aRet,Alltrim((cAliasTrb)->MENU_ID))
		AADD(aRet,Alltrim((cAliasTrb)->DESC_PT))
		AADD(aRet,Alltrim((cAliasTrb)->DESC_ES))
		AADD(aRet,Alltrim((cAliasTrb)->DESC_EN))
		AADD(aRet,Alltrim((cAliasTrb)->FUNCAO))
		AADD(aRet,Alltrim((cAliasTrb)->I_TYPE))
		AADD(aRet,Alltrim((cAliasTrb)->I_TABLES))
		AADD(aRet,Alltrim((cAliasTrb)->ACESSO))
		AADD(aRet,Alltrim((cAliasTrb)->M_MODULE))
		AADD(aRet,Alltrim((cAliasTrb)->I_OWNER))
		AADD(aRet,Alltrim((cAliasTrb)->USR_CODMOD))
		AADD(aRet,Alltrim((cAliasTrb)->I_ID))
		AADD(aRet,Alltrim((cAliasTrb)->I_ORDER))
		AADD(aRet,Alltrim((cAliasTrb)->I_TYPE))
		AADD(aRet,Alltrim((cAliasTrb)->I_MODULE))
		AADD(aRet,Alltrim((cAliasTrb)->I_STATUS))

	EndIf

	(cAliasTrb)->(DbCloseArea())

Return aRet

