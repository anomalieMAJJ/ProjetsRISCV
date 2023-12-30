# Implémentation d'une structure de donnée « corde » pour manipuler des chaines de caractères.

.data
	.global newRope
	.global str2Rope
	.global lenRope
	.global printRope
	.global splitRope
	.global concatRope
	
	.eqv Sbrk, 9			
	.eqv Write, 64			
	.eqv stdout, 1			
	.eqv tailleCorde, 16		# taille d'une corde unaire en octets
	.eqv offsetRLen, 0		# champ "taille" (dword), int d'une taille en octets
	.eqv offsetRData, 8 		# champ "donnée" (dword), adresse d'un tableau de caractères
	.eqv nullByte, 0		# nullByte '\0' de la fin d'une chaîne de caractères
	.eqv offsetRLeft, 8		
	.eqv offsetRRight, 16 		
	.eqv tailleCordeBinaire, 24	# taille d'une corde binaire en octets

.text

# Routine newRope qui prend en paramètres l'adresse d'un tableau de caractères et la taille du tableau
# de caractères et retourne l'adresse d'une nouvelle code unaire allouée dans le tas.
newRope: 
	# PROLOGUE
	addi sp, sp, -24		
	sd ra, 0(sp)		
	sd s0, 8(sp)		
	sd s1, 16(sp)		

	mv s0, a0			# adresse d’un tableau de caractères (rData)
	mv  s1, a1			# taille du tableau de caractères (rLen)

	# retrouver l'adresse du tas
	li a7, Sbrk
	li a0, tailleCorde
	ecall

	# mettre les informations dans le tas
	sd s1, offsetRLen(a0)		# rLen va dans la corde à l'offsetRLen de a0
	sd s0, offsetRData(a0)		# rData va dans la corde à l'offsetRData de a0

	# EPILOGUE
	ld ra, 0(sp)		
	ld s0, 8(sp)		
	ld s1, 16(sp)		
	addi sp, sp, 24		
	
	ret				# a0 a déjà la bonne valeur (adresse de la nouvelle corde unaire)


# Routine str2Rope qui prend en paramètre l'adresse d'une chaîne de caractères terminée par '\0'
# et retourne l'adresse d'une nouvelle corde unaire allouée dans le tas.
str2Rope:
	# PROLOGUE
	addi sp, sp, -16		
	sd ra, 0(sp)		
	sd s0, 8(sp)		
	
	mv s0, a0			# adresse d’un tableau de caractères (rData)
	
s2RlongChaine: 				# trouver rLen pour pouvoir appeler newRope avec les deux paramètres requis
	li t0, 0			# initialise le compteur à zéro
	mv t2, s0
	
s2RCompteur:
	lbu t1, (t2)
	beqz t1, s2RFinCompteur		# si t1 = 0 : fin
        addi t0, t0, 1			# sinon : incrémentation du compteur
        addi t2, t2, 1			# 	  passer à l'indice suivant du tableau
        j s2RCompteur		

s2RFinCompteur:
	mv a0, s0			
	mv a1, t0			
	jal newRope			# création de la corde

	# ÉPILOGUE
	ld ra, 0(sp)		
	ld s0, 8(sp)		
	addi sp, sp, 16		
	
	ret				# a0 (adresse de la corde) a déjà la bonne valeur


# Routine lenRope qui prend en paramètre l'adresse d'une corde et retourne sa taille 
# (son nombre de caractères).
lenRope: 
	ld a0, offsetRLen(a0)
	bgez a0, lRFin			# si a0 >= 0 : fin (chaîne unaire)
	
lRBinaire:				# sinon a0 < 0 : (chaîne binaire)
	neg a0, a0			
	
lRFin:
	ret
	

# Routine printRope qui prend en paramètre l'adresse d'une corde et affiche son contenu à l'écran.
printRope:
	# PROLOGUE
	addi sp, sp, -16		
	sd ra, 0(sp)		
	sd s0, 8(sp)		

	mv s0, a0			# adresse de la corde dans s0

	ld a2, offsetRLen(s0)
	bltz a2, pRBinaire		# si a2 < 0 : pRBinaire (corde binaire)

pRUnaire:				# sinon a2 >= 0 : pRUnaire (corde unaire)
	li a7, Write		
	li a0, stdout		
	ld a1, offsetRData(s0)	
	ld a2, offsetRLen(s0)	
	ecall
	j pRFin

pRBinaire:
	ld a0, offsetRLeft(s0)	
	jal  printRope			# imprimer la corde de gauche
	
	ld a0, offsetRRight(s0)	
	jal printRope			# imprimer la corde de droite
	
pRFin:		
	# ÉPILOGUE
	ld ra, 0(sp)		
	ld s0, 8(sp)		
	addi sp, sp, 16		
	
	ret


# Routine splitRope qui prend en paramètre l'adresse d'une corde (a0) et un index (a1). La routine 
# retourne deux cordes : la première contient les a1 premiers caractères et la seconde corde (a1)
# contient les autres caractères.
splitRope:
	# PROLOGUE
	addi  sp, sp, -48		
	sd ra, 0(sp)		
	sd s0, 8(sp)		
	sd s1, 16(sp)		
	sd s2, 24(sp)		
	sd s3, 32(sp)		
	sd s4, 40(sp)		

	mv s0, a0			# adresse d'une corde
	mv s1, a1			# index
	
	ld t0, offsetRLen(s0)
	bltz t0, splitBinaire		# Si t0 < 0 : corde binaire
					# Sinon unaire
	ld a0, offsetRData(s0)
	jal newRope			# a0 et a1 contiennent déjà les bons paramètres
	mv s2, a0 			# conserver la corde gauche dans s2 
	
	ld t1, offsetRData(s0)
	add a0, t1, s1			# adresse de la corde de droite
	ld t2, offsetRLen(s0)	
	sub a1, t2, s1			# taille de la corde de droite
	jal newRope
	
	mv a1, a0			# a1 = corde de droite
	mv a0, s2			# a0 = corde gauche
	j splitFin
	
splitBinaire:
	ld a0, offsetRLeft(s0)
	jal lenRope
	mv s4, a0
	bne s4, s1, splitBinSuite1	# si s4 != index : binaireSuite1
	
	ld a0, offsetRLeft(s0)		# 	adresse de la corde gauche
	ld a1, offsetRRight(s0)		# 	adresse de la corde droite
	j splitFin

splitBinSuite1:	
	bgt s1, s4, splitBinSuite2	# si s4 > index : binaireSuite2
	ld a0, offsetRLeft(s0)		# 	adresse de la corde gauche
	mv a1, s1			# 	index
	jal splitRope
	mv s3, a0			# 	s3 = corde de gauche
	mv a0, a1			# 	a0 = corde de droite
	ld a1, offsetRRight(s0)		
	jal concatRope
	mv a1, a0			# 	a1 = corde de droite
	mv a0, s3			# 	a0 = corde de gauche
	j splitFin
	
splitBinSuite2:				# sinon s4 <= index
	ld a0, offsetRRight(s0)
	sub a1, s1, s4			# 	a1 = index - lenLeft
	jal splitRope
	mv s4, a1			# 	s4 = corde de droite
	mv a1, a0			#	a1 = corde de gauche
	ld a0, offsetRLeft(s0)
	jal concatRope			# 	a0 = corde de gauche
	mv a1, s4			# 	a1 = corde de droite

splitFin:	
	# EPILOGUE
	ld ra, 0(sp)		
	ld s0, 8(sp)		
	ld s1, 16(sp)		
	ld s2, 24(sp)		
	ld s3, 32(sp)		
	ld s4, 40(sp)		
	addi sp, sp, 48		
	
	ret


# Routine concatRope qui prend en paramètre les adresse de deux cordes (a0 et a1) et retourne une
# corbe binaire allouée dans le tas.
concatRope: 
	# PROLOGUE
	addi sp, sp, -40		
	sd ra, 0(sp)		
	sd s0, 8(sp)		
	sd s1, 16(sp)		
	sd s2, 24(sp)		
	sd s3, 32(sp)

	mv s0, a0			# adresse de la première corde
	mv s1, a1			# adresse de la deuxième corde

	# retrouver l'adresse du tas
	li a7, Sbrk
	li a0, tailleCordeBinaire
	ecall
	mv s3, a0
	
	mv a0, s0
	jal lenRope
	mv s2, a0			# longueur de la corde gauche
	mv a0, s1
	jal lenRope			# longueur de la corde droite
	add t0, a0, s2			# t0 = lenRight + lenLeft
	neg t0, t0
	
	# mettre les informations dans le tas
	sd t0, offsetRLen(s3)
	sd s0, offsetRLeft(s3)
	sd s1, offsetRRight(s3)
	
	mv a0, s3
	# EPILOGUE
	ld ra, 0(sp)		
	ld s0, 8(sp)		
	ld s1, 16(sp)		
	ld s2, 24(sp)		
	ld s3, 32(sp)
	addi sp, sp, 40		
	
	ret				# a0 contient déjà la valeur de la corde binaire à retourner
