LOCALS @@

.MODEL small
.STACK 256

.DATA
;;;komandines eilutes argumentai
failoVardas1 DB 127 DUP(0)
failoVardas2 DB 127 DUP(0)
atsFailoVardas DB 127 DUP(0)

dvejetainis1 DB 255 DUP(0)
dvejetainis2 DB 255 DUP(0)

rezultatas DB 255 DUP(0)

programosAprasymas DB "Programa skaiciuoja sudeti dvieju dvejetainiu skaiciu, kurie yra nurodytuose failuose, ir suma paraso i nurodyta atsakymu faila", 10, 13, '$'
pagalbosPranesimas DB "Naudojimas: prak2 <failo_vardas> <failo_vardas> <atsakymo_failo_vardas>", 10, 13, '$'

tek DB "Darbas ivykdytas sekmingai. Atsakymu failas sugeneruotas", 10, 13, '$'
.CODE
Start:	
	push ds

	mov ax, @data
	mov ds, ax

	pop es

	call NuskaitytiArgumentus
	jc Pagalba

	mov dx, offset failoVardas1
	mov ax, offset dvejetainis1
	call NuskaitytiFaila
	jc Pagalba

	mov dx, offset failoVardas2
	mov ax, offset dvejetainis2
	call NuskaitytiFaila
	jc Pagalba

	call Sudeti

	mov dx, offset tek
	call Printinti

	call AtsakymoFailas
	jc Pagalba
	
	call UzdarytiFaila
	jc Pagalba

	jmp Exit

Pagalba:
	mov dx, offset programosAprasymas
	call Printinti

	mov dx, offset pagalbosPranesimas
	call Printinti

	jmp Exit
Exit:	
	mov ah, 04Ch
	int 21h

;;; DX SKAITOMO FAILO ADRESAS
;;; AX KINTAMOJO KURIAME IRASYTI ADRESAS
PROC NuskaitytiFaila
	push ax
	
	call AtidarytiFaila
	jc @@ExitPop

	;; issaugo bylos deskriptoriu
	mov bx, ax

	pop ax

	mov dx, ax
	mov ax, bx
	call SkaitytiFaila
	jc @@Exit
	
	call UzdarytiFaila
	jc @@Exit

	jmp @@Exit

@@ExitPop:
	pop ax 
	jmp @@Exit

@@Exit:
	ret
ENDP


;;; NAUDOJA DX REGISTRA FAILUI KURI ATIDARYTI
;;; GRAZINA AX BYLOS DESKRIPTORIU
PROC AtidarytiFaila
	mov ah, 3Dh
	mov al, 0h
	int 21h

	ret
ENDP

;;; NAUDOJA AX REGISTRA BYLOS DESKRIPTORIUI, DX ADRESA KUR RASYTI
;;; GRAZINA BX BYLOS DESKRIPTORIU
PROC SkaitytiFaila
	mov bx, ax
	mov ah, 3Fh
	mov cx, 255
	int 21h

	ret
ENDP

;;; NAUDOJA BX REGISTRA, BYLOS DESKRIPTORIUI
PROC UzdarytiFaila
	mov ah, 3Eh

	ret
ENDP

;;; NAUDOJA DX REGISTRA KURIAME TURI BUTI ADRESAS
;;; GRAZINA ILGI STRINGO BX REGISTRE
PROC GautiIlgi
	mov bx, dx
	
@@Repeat:
	mov al, BYTE PTR [ds:bx]

	cmp al, 0
	je @@Exit

	inc bx
	
	jmp @@Repeat

@@Exit:
	sub bx, dx
	ret
ENDP

;;; NUSKAITO ARGUMENTUS IS KOMANDINES EILUTES
;;; IJUNGIA CF FLAGA JEI ARGUMENTAI NEKOREKTISKA
PROC NuskaitytiArgumentus
	;; ilgis komandines eilutes issaugomas
	mov ax, 0
	mov al, BYTE PTR [es:80h]

	;; jeigu nera argumentu tada baigti darba	
	cmp al, 0
	je @@ExitHelp

	;; argumento adresas
	mov bx, offset failoVardas1

	;; komandines eilutes indeksas
	mov di, 1

	;; argumento indeksas
	mov si, 0
	
	;; komandines eilutes simbolis dabartinis
	mov dl, 0

@@Repeat:
	mov dl, BYTE PTR [es:81h + di]
	cmp ax, di
	jne @@Argumentas

	jmp @@Exit

@@Argumentas:
	cmp dl, ' '
	je @@ArgumentasParasytas

	mov BYTE PTR [bx + si], dl
	inc si
	inc di

	jmp @@Repeat

@@ArgumentasParasytas:
	;; patikrina ar nebando rasyti daugiau argumentu nei galima
	cmp atsFailoVardas, 0
	jne @@ExitHelp

	mov si, 0

	;; pereina prie kito argumento 
	;; !! KIEKVIENAS ARGUMENTAS PRIVALO BUTI 127 ILGIO
	add bx, 127

	inc di

	jmp @@Repeat

@@Exit:
	;; patikra ar visi argumentai buvo aprasyti
	cmp failoVardas1, 0
	je @@ExitHelp

	cmp failoVardas2, 0
	je @@ExitHelp
	
	cmp atsFailoVardas, 0
	je @@ExitHelp

	ret

@@ExitHelp:
	;; ijungia cf flaga, nekorektiska ivestis
	stc

	ret
ENDP

;;; SUDEDA DU BINARY SKAICIUS
;;; REZULTATAS PATALPINAMAS I STACKA
PROC Sudeti
	mov ax, 0

	;; suma
	mov al, 0

	mov dx, offset dvejetainis1
	call GautiIlgi

	;; bx registre gaunamas ilgis
	dec bx

	;; bin1 adresas
	mov si, offset dvejetainis1
	add si, bx
	;; paskutinis yra carriage return delto -1
	dec si

	mov dx, offset dvejetainis2
	call GautiIlgi

	;; bx registre ilgis dvejetainio
	dec bx

	;; bin2 adresas
	mov di, offset dvejetainis2
	add di, bx
	;; paskutinis yra carriage return delto -1
	dec di

	push '$'

@@Repeat:
	cmp si, offset dvejetainis1
	jb @@TikDvejetainis2

	cmp di, offset dvejetainis2
	jb @@TikDvejetainis1

	jmp @@AbuDvejetainiai

@@AbuDvejetainiai:
	add al, BYTE PTR[ds:di]
	sub al, '0'
	add al, BYTE PTR[ds:si]
	sub al, '0'

	jmp @@Suma

@@TikDvejetainis1:
	cmp si, offset dvejetainis1
	jb @@Exit

	add al, BYTE PTR[ds:si]
	sub al, '0'

	jmp @@Suma

@@TikDvejetainis2:
	cmp di, offset dvejetainis2
	jb @@Exit

	add al, BYTE PTR[ds:di]
	sub al, '0'

	jmp @@Suma

@@Suma:
	cmp al, 1
	ja @@SumaDidesne

	jmp @@SumaMazesne

@@SumaDidesne:
	sub al, 2
	push ax

	mov al, 1

	jmp @@EndRepeat

@@SumaMazesne:
	push ax
	
	mov al, 0

	jmp @@EndRepeat

@@EndRepeat:
	dec di
	dec si

	jmp @@Repeat

@@Exit:
	cmp al, 1
	je @@PridetiViena

	jmp @@SurasytiRezultata

@@PridetiViena:
	mov al, 1
	push ax

	jmp @@SurasytiRezultata

@@SurasytiRezultata:
	mov bx, 0
	
@@SurasytiRepeat:
	pop ax
	cmp ax, '$'
	je @@BaigeSurasyma
	
	add al, '0'
	mov [rezultatas + bx], al

	inc bx
	jmp @@SurasytiRepeat

@@BaigeSurasyma:
	ret

ENDP

;;; GRAZINA BX BYLOS DESKRIPTORIU
PROC AtsakymoFailas
	;; FAILO SUKURIMAS

	mov ah, 3Ch
	mov cx, 0

	mov dx, offset atsFailoVardas
	int 21h

	jc @@Exit

	;; RASYMAS I FAILA

	mov dx, offset rezultatas

	;; issaugomas deskriptorius
	push ax

	;; apskaiciavimas elementu skaiciu, kuriuos rasyti
	call GautiIlgi
	mov cx, bx
	
	;; addresas nuo kur pradeti skaityti
	mov dx, offset rezultatas

	pop ax
	mov bx, ax
	mov ah, 40h	

	int 21h
@@Exit:
	ret	
ENDP

PROC Printinti
	mov ah, 9h
	int 21h

	ret
ENDP

END Start

