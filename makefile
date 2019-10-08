cmm : cmm.l cmm.y cmm_func.h cmm_func.c
	flex cmm.l
	bison -d cmm.y
	gcc -o $@ cmm.tab.c lex.yy.c cmm_func.c -ll