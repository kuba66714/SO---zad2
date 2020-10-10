DEFAULT REL
extern pixtime
STACKVAR equ 0xFFFFFFFFFFFF8000

section .data
	align 4
	spin_lock dd 0		

section .text
%macro divFrac 2 
	mov rax, %1		;zapisuje liczbe do podzienia w rax
	xor rdx, rdx		;zeruje rdx, zeby nie brac wiekszej 
	div %2			;dziele przez drugi argument
	xor rax, rax		;zostawiam reszte, zeruje iloraz
	div %2			;dziele jeszcze raz
%endmacro
%macro fracMul 2		;mnozy dwie liczby przez siebie
	mov rax, %1		;pierwszy czynnik zapisuje w rax
	mul %2			;mnoze przez drugi
	mov rax, rdx		;zwracam wynik w rax
%endmacro

%macro GetSj 2			;funkcja liczy wartosci Sj ze wzoru
				;przyjmuje 2 argumenty w rdi i rsi
	xor rdx, rdx
	xor r10, r10		;tu zapisuje wynik
	xor r8, r8 		;licznik petli
	mov r9, %2		;tu zapisuje n
	inc r9			;r9=n+1
	mov r12, %1		;r12 = j
%%loop2:
	mov rdi, r9		;rdi = n+1
	dec rdi			;rdi = n
	sub rdi, r8		;rdi = n-k
	mov rax, r8		;rax = k
	mov rcx, 8		;rcx = 8
	mul rcx			;rax = 8*k
	add rax, r12		;rax = 8*k+j
	mov r13, rax		;r13 = 8*k+j
	mov rsi, rax		;rsi = 8*k+j
	pow_modulo rdi, rsi

	divFrac rax, r13	;czesc ulamkowa rax/r13
	add r10, rax		;wynik dodaje do wyniku

	inc r8			;zwiekszam licznik petli
	cmp r8, r9		;sprawdzam czy koncze petle
	jne %%loop2
	
	mov rdi, 1
	mov rsi, 16
	divFrac rdi, rsi	;obliczam ulamek 1/16

	mov r8, rax		;w r8 zapisuje 1/16
	mov r13, rax		;w r13 tez
%%loop3:
	mov rax, r9		;r9 jest licznikiem petli od n+1
	mov rcx, 8
	mul rcx			;rax = 8*k k=n+1,...
	add rax, r12		;rax = 8*k+j
	mov rcx, rax		;rcx= 8*k+j
	mov rax, r8		;tu zapisuje poprzedni wynik petli
				;lub 1/16 jesli to pierwszy
	div rcx			;dziele przez 8k+j
	cmp rax, 0		
	je %%_ret		;jesli po dzieleniu dostaje 0
				;to koncze
	add r10, rax		;dodaje wynik do ostatecznego 
	fracMul r8, r13		;czesc calkowita r8/r13
	mov r8, rax		;wynik dzielenia zapisuje w r8
	inc r9			;zwiekszam licznik petli
	jmp %%loop3

%%_ret:
	mov rax, r10		;wynik zwracam w rax
%endmacro

%macro getRes 1			;oblicza wynik dla n=8m
	mov r14, %1
	mov rsi, %1
	mov rdi, 1
	mov r11, 4		;r11 jest jednoczesnie liczba przez
				;ktora nalzy wymnozyc wynik
				;oraz wskazuje, w ktore miejsc w kodzie
				;nalezy skoczyc po wykonaniu GetSj
%%zrobGetSj:
	GetSj rdi, rsi		;wywoluje funkcje z argumentami 1, n
	cmp r11, 2
	je %%po4n
	cmp r11, 1
	je %%po5n
	cmp r11, 0
	je %%koniec	
	mul r11			;mnoze wynik razy 4
	mov r15, rax		;zapisuje wynik w r15

	mov rdi, 4
	mov rsi, r14
	mov r11, 2
	jmp %%zrobGetSj		;wywoluje funkcje z argumentami 4, n
%%po4n:
	mul r11			;mnoze wynik razy 2
	sub r15, rax		;i odejmuje od ostatecznego	

	mov rdi, 5		
	mov rsi, r14
	mov r11, 1
	jmp %%zrobGetSj		;wywoluje funkcje z argumentami 5, n
%%po5n:
	sub r15, rax		;i odejmuje od wyniku
	
	mov rdi, 6		;wywoluje funkcje z argumentami 6, n
	mov rsi, r14		;i odejmuje od wyniku
	mov r11, 0
	jmp %%zrobGetSj
%%koniec:
	sub r15, rax		;ostateczny wynik zapisuje w rax
	mov rax, r15
%endmacro

%macro pow_modulo 2
	xor rax, rax
	cmp %2, 1		;sprawdzam, czy bede dzielic przez 1
	je %%ret_pow		;jesli tak to zwracam 0
	mov rax, 1
	test %1, %1		;jesli nie dziele przez 1 to sprawdzam,
				;czy podnosze do potegi 0
	je %%ret_pow		;jesli tak to zwracam 1
	mov rax, 16		
	mov rbx, 1		
	xor rdx, rdx		;zeruje rdx, zeby nie brac za duzej liczby
	div %2			;dziele 16 przez podany dzielnik
	mov rcx, rdx		;wynik zapisuje w rcx
%%loop_pow:	
	test %1, %1		;sprawdzam, czy wykonuje obrot petli 
	je %%ret_pow		;jesli rdi jest 0 to nie
	
	test dil, 1		;sprawdzam, czy rdi jest parzyste
	je %%parzyste		;jesli wyszlo 0 tzn, ze rdi jest parzyste
	mov rax, rbx		;wpp mnoze rbx
	xor rdx, rdx		;zeruje rdx, zeby nie brac za duzej liczby
	mul rcx			;mnoze wynik przez rcx
	div %2			;biore reszte modulo rsi
	mov rbx, rdx		;tymczasowy wynik zapisuje w rbx
%%parzyste:
	mov rax, rcx		;jesli jest parzyste
	xor rdx, rdx		;zeruje rdx
	mul rcx			;podnosze rcx do kwadratu
	div %2			;dziele przez rsi
	mov rcx, rdx		;reszte zapisuje w rcx
	shr %1, 1		;dziele wykladnik przez 2
	mov rax, rbx		;wynik zapisuje w rax
	jmp %%loop_pow
%%ret_pow:
%endmacro
global pix

pix:
			
	mov rcx, rbp		
	push rcx		;zapisuje na stosie wartosci
				;rejestrow, ktore nie moga byc zmienione
	push rbx		
	push r12
	push r13
	push r14
	push r15
	
	push rsi
	push rdi
	push rdx
	mov rbp, rsp		;w rbp zachowuje aktualny adres stosu

	rdtsc			;liczbe cykli zapisuje w edx:eax
	mov edi, edx		;zapisuje wyzsze 32 bity w edi
	shl rdi, 32		;przesuwam o lewo o 32 bity
	or rdi, rax		;zapisuje nizsze 32 bity
	and rsp, STACKVAR	;wyrownuje stos, zeby byl podzielny przez 16
	call pixtime		;wywoluje pixtime z C

	mov rsp, rbp		;przywracam stary adres stosu
	pop rdx			;zdejmuje ze stosu wartosci argumentow
	pop rdi
	pop rsi
	mov rbp, rsp		;zapisuje adres stosu w rbp
	
_mainloop:
	mov r15, 1		;o tyle zwieksze indeks
	lock xadd qword [rsi], r15 ;zwiekszam wsplony indeks
				;a poprzednia wartosc zapisuje w r15
	
	cmp r15, rdx		;sprawdzam, czy lokalny indeks
				;jest mniejszy niz maksymalny
	jae end			;jesli nie to koncze watek
				
	push rsi		;zapisuje argumenty na stosie
	push rdi
	push rdx
	push r15		;wrzucam na stos rowniez indeks, ktorego
				;wartosc bede liczyl
	
	mov rax, r15		;w rax zapisuje wartosc indeksu
	mov r8, 8		
	mul r8			;mnoze indeks przez 8
	getRes rax		;makro liczace cyfry liczby pi

	shr rax, 32		;biore lewe 32 bity
	pop rbx			;w rbx zapisuje adres indeksu
				;biore go ze stosu
	pop rdx			;zdejuje argumenty
	pop rdi
	pop rsi
	mov dword [rdi+ 4*rbx], eax	;w odpowiednim miejscu w tablicy
					;zapisuje obliczona liczbe
	
	
	jmp _mainloop		;wykonuje obrot petli
end:	
	
	rdtsc			;liczbe cykli zapisuje w edx:eax
	mov edi, edx		;zapisuje wyzsze 32 bity w edi
	shl rdi, 32		;przesuwam o lewo o 32 bity
	or rdi, rax		;zapisuje nizsze 32 bity
	and rsp, STACKVAR	;wyrownuje stos, zeby byl podzielny przez 16
	call pixtime		;wywoluje pixtime z C

	mov rsp, rbp
	pop r15			;przywracam wartosci rejestrow
	pop r14
	pop r13
	pop r12
	
	pop rbx
	pop rbp

	ret
	



