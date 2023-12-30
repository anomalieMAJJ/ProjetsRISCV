# Jeu de puissance 4
#
# Implémentation du jeu Puissance 4 permettant à deux joueurs humains de s’affronter 
# dans un duel cognitif et psychologique.

	.data
	msgErr:		.asciz "Erreur d'entrée."
	msgTourP1:	.asciz "Le joueur "
	msgTourP2:	.asciz " doit jouer."
	msgGagneP1:	.asciz "Le joueur "
	msgGagneP2:	.asciz " gagne."
	msgPerdP1:	.asciz "Le joueur "
	msgPerdP2:	.asciz " perd."
	msgLignePerd:	.asciz "........."
	
matrice:
	.ascii 	".........................................."	# 42 points
	.eqv 	nbColMax, 7 					# Nombre de colonnes
	.eqv	nbLigneMax, 6					# Nombre de lignes

tabJoueur:
	.byte	 'X', 'O'					# Les deux options de joueurs
	.eqv 	tabJoueurLen, 2

	# Appels système RARS utilisés
	.eqv 	PrintInt, 1
	.eqv	PrintStr, 4
	.eqv 	Exit, 10
	.eqv	Exit2, 93
	.eqv 	PrintChar, 11
	.eqv	ReadChar, 12
	.eqv 	quit, 'q'
	.eqv	printGame, 'd'
	.eqv	sautLigne, 10					# 10 = '\n'
	.eqv	espace, 32					# 32 = ' '
	.eqv    minCol, 0x31
	.eqv	maxCol, 0x37	
	.eqv	point, 46					# 46 = '.'
	.eqv	maxJeton, 4					
	
	.text

	li	s8, 0			# Indicateur de tour. Joueur 0 = 'X', Joueur 1 = 'O'
	la 	s9, matrice		# s9 = adresse de la matrice
	
loop:
	li 	a7, ReadChar
	ecall
	mv 	s0, a0			# s0 = colonne choisie par le joueur
	la 	t2, tabJoueur
	add	t2, t2, s8
	lbu	s7, (t2)		# s7 = tabJoueur[s8] 
	li	t1, sautLigne
	beq 	s0, t1, loop       	# Ignorer les sautLignes '\n'
	li	t1, espace
	beq	s0, t1, loop		# Ignorer les eespaces ' '
	li	t1, quit
	beq	s0, t1, fin		# Fin du programme si le caractère saisit est 'q'
	li	t1, printGame		# Si s0 = 'd', afficher la matrice 
	bne	s0, t1, playLoop	# Sinon, mettre le jeton dans la colonne choisie par le joueur
	la	a0, matrice
	mv	a1, s7
	jal	affichage		# Affiche la matrice
	# Affiche le joueur à qui c'est le tour de jouer
	la 	a0, msgTourP1		
	mv	a1, s7			
	la	a2, msgTourP2		
	jal	prntStr	
	j 	loop	
	
playLoop:
	li	t1, minCol		# t1 = 1
	blt	s0, t1, erreur		# Si s0 < 1, erreur
	li	t1, maxCol		# t1 = 7
	bgt 	s0, t1, erreur		# Si s0 <= 7, on peut ajouter le jeton, sinon erreur
	addi	s0, s0, -minCol		# 	s0 = int(s0) - 1
	mv	a0, s0
	la	a1, matrice
	mv	a2, s7	
	jal	jouer			# Placer un jeton
	mv	a3, a0			
	mv 	a0, s7			
	mv	a1, s0	
	mv	a2, s9	
	jal	testVictoire		# Nouveau jeton = tester s'il y a victoire
	xori	s8, s8, 1		# offset de 0 à 1 à 0 pour changer de joueur (index de tabJoueur)
	j	loop


## Fonction "jouer" qui prend un numero de colonne, une adresse de tableau de 42 bytes en paramètre et 
# un charactere representant un joueur, modifie la matrice et retourne la ligne (y) du jeton placé
jouer:
	# PROLOGUE
	addi 	sp, sp, -40		# Assez de pile pour 4 registre (adresse de retour + 4 sX)
	sd	ra, 0(sp)		
	sd	s0, 8(sp)		
	sd	s1, 16(sp)		
	sd	s2, 24(sp)		
	sd	s3, 32(sp)		
	
	mv 	s0, a0			# s0 = colonne choisie
	mv	s1, a1			# s1 = adresse de la matrice
	mv 	s2, a2			# s2 = joueur
	li 	s3, 0			# s3 = 0 (suivi du nombre de lignes)
	
# Vérifier la première ligne, si un jeton s'y trouve, le joueur perd, sinon, il peut jouer
validPeutJouer:
	add 	t0, s1, s0		# t0 = adresse de la matrice + colonne choisie
	lbu	t1, (t0)		# t1 = indice 0 du tableau t0
	li 	t3, point		# t3 = '.'
	beq	t1, t3, validJouer	# Si t1 = '.' { validJouer }
	mv	a0, s2			# Sinon {	a0 = s2
	mv	a1, s0			# 	   	a1 = s0
	mv	a2, s1			#	   	a2 = s1
	jal 	joueurPerd		# 	  	joueurPerd }
	addi	s3, s3, 1		# s3 = ligne à venir
	
# Vérifier que le jeton ne peut pas descendre plus bas dans la grille
validJouer:
	addi	t1, t0, nbColMax	# t1 = adresse de la ligne suivante
	lbu	t2, (t1)		# t2 = le contenu à la ligne suivante
	li	t3, point		# t3 = emplacement sans jeton
	bne	t2, t3, place		# Si t2 != '.', on place le jeton dans la ligne actuelle
	mv	t0, t1			# Sinon, ligne suivante devient la ligne actuelle
	li	t6, nbLigneMax
	addi	s3, s3, 1		# s3 = ligne à venir
	beq	s3, t6, place		# Si ligne à venir = 6, placer le jeton dans le bas de la grille
	j	validJouer

place:
	sb	s2, (t0)		# Place le jeton dans la grille
	mv	a0, s3			# Retourne la ligne dans laquelle se trouve le jeton
	# ÉPILOGUE
	ld	ra, 0(sp)		
	ld	s0, 8(sp)		
	ld 	s1, 16(sp)		
	ld	s2, 24(sp)		
	ld	s3, 32(sp)		
	addi 	sp, sp, 40		
	ret


# Fonction "verifVictoire" qui vérifie à chaque tour de jeu si le joueur a gagné ou non. 
# Prend en entrée le joueur, le x et le y de la première case à vérifier, la matrice, le 
# déplacement de x (delta x) et de y (delta y)
verifVictoire: 
	# PROLOGUE
	addi 	sp, sp, -56		# Assez de pile pour 4 registre (adresse de retour + 6 sX)
	sd	ra, 0(sp)		
	sd	s0, 8(sp)		
	sd	s1, 16(sp)		
	sd 	s2, 24(sp)		
	sd	s3, 32(sp)		
	sd	s4, 40(sp)		
	sd	s5, 48(sp)		
	
	mv 	s0, a0			# Joueur
	mv	s1, a1			# x (début)
	mv	s2, a2			# Matrice
	mv	s3, a3			# y (début)
	mv	s4, a4			# delta x
	mv	s5, a5			# delta y
	
	li 	t0, 0			# t0 = compteur de jetons, initialisé à 0
	li	t1, nbColMax		
	li	t2, nbLigneMax		
	li	t6, maxJeton	
	
vvLoop:	
	# Obtenir l'adresse de la case dans le tableau
	mul	t3, s3, t1		# t3 = 7 * y
	add	t3, t3, s2		# t3 = tableau + 7y
	add	t3, t3, s1		# t3 = tableau + 7y + x
	
	lbu	t4, (t3)		# t4 = le contenu de t3
	beq	t4, s0, vvIncrement	# Si t4 = s0 (si le jeton est là), on incrémente
	li	t0, 0			# Sinon, remise à zéro du compteur de jetons
	j	vvAppliqueDelta		# 	 et on va appliquer le delta
	
vvIncrement:
	addi	t0, t0, 1		# Compteur de jetons + 1
	bne	t0, t6, vvAppliqueDelta	# Si t0 != 4, on passe à la prochaine vérification
	mv	a0, s0			# Sinon, t0 = 4 
	jal	joueurGagne		# 	Le joueur gagne	
	
vvAppliqueDelta:
	add	s1, s1, s4		# x = x + delta x
	bltz	s1, vvFin		# Hors limite (x < 0)
	bge	s1, t1, vvFin		# Hors limite (x >= 7)
	add	s3, s3, s5		# y = y + delta y
	bltz	s3, vvFin		# Hors limite (y < 0)
	bge	s3, t2, vvFin		# Hors limite (y >= 6)
	j	vvLoop	
	
vvFin:
	# ÉPILOGUE
	ld	ra, 0(sp)		
	ld	s0, 8(sp)		
	ld 	s1, 16(sp)		
	ld	s2, 24(sp)		
	ld	s3, 32(sp)		
	ld	s4, 40(sp)		
	ld	s5, 48(sp)		
	addi 	sp, sp, 56		
	ret


# Fonction "testVictoire" qui permet de tester les 4 types de victoires possibles : horizontale, 
# verticale et les deux diagonales. Prend en entrée le joueur, la colonne et la ligne du jeton ainsi
# que la matrice et retourne le joueur, le x et le y de la première case à vérifier, les delta x et y
# des déplacements à exécuter ainsi que la matrice.
testVictoire:
	# PROLOGUE
	addi 	sp, sp, -40		# Assez de pile pour 4 registre (adresse de retour + 4 sX)
	sd	ra, 0(sp)		
	sd	s0, 8(sp)		
	sd	s1, 16(sp)		
	sd 	s2, 24(sp)		
	sd	s3, 32(sp)		

	mv 	s0, a0			# Joueur
	mv	s1, a1			# Colonne du jeton
	mv	s2, a2			# Matrice
	mv	s3, a3			# Ligne du jeton
	
verifHorizontale:
	li	t1, 0			# x : on commence la recherche à l'indice 0
	li	t4, 1			# Delta x : Déplacement de 1 sur l'axe des x
	li	t5, 0			# Delta y : Aucun déplacement sur l'axe des y

	mv	a0, s0 			# Joueur	
	mv	a1, t1			# x (début)
	mv	a2, s2			# Matrice
	mv	a3, s3			# y = ligne du jeton
	mv	a4, t4			# Delta x
	mv	a5, t5			# Delta y
	jal	verifVictoire		
	
verifVerticale:
	li	t4, 0			# Delta x : Aucun déplacement sur l'axe des x
	li	t5, 1			# Delta y : Déplacement de 1 sur l'axe des y

	mv	a0, s0			# Joueur	
	mv	a1, s1			# x = colonne choisie
	mv	a2, s2			# Matrice
	mv	a3, s3			# y = ligne du jeton
	mv	a4, t4			# Delta x
	mv	a5, t5			# Delta y
	jal	verifVictoire
	
# HGBD = Diagonale de haut gauche à bas droit
verifDiagHGBD:	
	li	t1, 0			# x initialisé à 0
	li	t3, 0			# y initialisé à 0
	beq	s1, s3, tvAppelHGBD	# Si jeton x == jeton y, va à tvAppel
	blt	s1, s3, tvPetitX	# Si jeton x < jeton y, va à tvPetitX
	sub	t1, s1, s3		# Sinon, x = jeton x - jeton y
	j	tvAppelHGBD
	
tvPetitX:
	sub	t3, s3, s1		# y = jeton y - jeton x
	
tvAppelHGBD:
	li	t4, 1			# Delta x : déplacement de 1 sur l'axe des x
	li	t5, 1 			# Delta y : déplacement de 1 sur l'axe des y

	mv	a0, s0			# Joueur	
	mv	a1, t1			# x (début)
	mv	a2, s2			# Matrice
	mv	a3, t3			# y (début)
	mv	a4, t4			# Delta x
	mv	a5, t5			# Delta y
	jal	verifVictoire	
	
# HDBG = Diagonale de haut droit à bas gauche
verifDiagHDBG:
	li	t1, 6			# x de début initialisé à 6
	li	t3, 0			# y de début initialisé à 0
	add	t6, s1, s3		# t6 = jeton x + jeton y
	bge	t6, t1, tvGrandSomme	# Si t6 >= 6, va à tvGrandSomme
	mv	t1, t6			# Sinon x = jeton x + jeton y		
	j	tvAppelHDBG		
	
tvGrandSomme: 
	sub	t3, t6, t1		# y = jeton y - (6 - jeton x)
	
tvAppelHDBG:
	#appel
	li	t4, -1			# Delta x : déplacement de -1 sur l'axe des x
	li	t5, 1			# Delta y : déplacement de 1 sur l'ace des y

	mv	a0, s0 			# Joueur	
	mv	a1, t1 			# x (début)
	mv	a2, s2			# Matrice
	mv	a3, t3			# y (début)
	mv	a4, t4			# Delta x
	mv	a5, t5			# Delta y
	jal	verifVictoire		
	
verifFin:
	# ÉPILOGUE
	ld	ra, 0(sp)	
	ld	s0, 8(sp)		
	ld 	s1, 16(sp)		
	ld	s2, 24(sp)		
	ld	s3, 32(sp)		
	addi 	sp, sp, 40		
	ret


# Fonction "affichage" permettant d'afficher la grille de jeu. Reçoit en paramètre la matrice et ne retourne rien.
affichage: 
	# PROLOGUE
	addi 	sp, sp, -16		# Assez de pile pour 2 registre (adresse de retour + 1 sX)
	sd	ra, 0(sp)		
	sd	s0, 8(sp)		
	
	mv	s0, a0			# s0 = matrice
	li	t2, 1			# t2 = 1
	li	a0, '\n'
	li 	a7, PrintChar		
	ecall		
			# Imprime un saut de ligne 
printligne:
	li 	a7, PrintChar
	li	a0, ':'
	ecall				# Imprime la bordure gauche ':'
	lbu	a0, 0(s0)
	ecall				# Imprime la ligne 0
	lbu	a0, 1(s0)
	ecall				# Imprime la ligne 1
	lbu	a0, 2(s0)
	ecall				# Imprime la ligne 2
	lbu	a0, 3(s0)
	ecall				# Imprime la ligne 3
	lbu	a0, 4(s0)
	ecall				# Imprime la ligne 4
	lbu	a0, 5(s0)
	ecall				# Imprime la ligne 5
	lbu	a0, 6(s0)
	ecall				# Imprime la dernière ligne
	li	a0, ':'
	ecall				# Imprime la bordure droite ':'
	li	a0, '\n'
	ecall				# Imprime les sauts de ligne
	
	addi	s0, s0, nbColMax	# s0 = s0 + 7
	addi	t2, t2, 1		# t2 = t2 + 1
	li	t1, nbLigneMax		# t1 = 6
	ble	t2, t1 printligne	# Si t1 <= t2, loop de printligne
	# EPILOGUE
	ld	ra, 0(sp)		
	ld	s0, 8(sp)		
	addi 	sp, sp, 16		
	ret


## Fonction "prntStr" permettant d'afficher 2 strings autour d'un char. Reçoit en paramètre le 
# début de la phrase, le char du joueur à afficher ainsi que la fin de la phrase et ne retourne rien.
prntStr:
	# PROLOGUE
	addi 	sp, sp, -32		# Assez de pile pour 4 registre (adresse de retour + 3 sX)
	sd	ra, 0(sp)	
	sd	s0, 8(sp)		
	sd	s1, 16(sp)		
	sd 	s2, 24(sp)		
	
	mv	s0, a0			# Début de phrase
	mv	s1, a1			# Joueur concerné
	mv	s2, a2			# Fin de phrase
	
	li	a7, PrintStr
	mv	a0, s0 			
	ecall				# Affiche le début de la phrase
	
	li	a7, PrintChar
	mv 	a0, s1
	ecall				# Affiche le joueur concerné
	
	li	a7, PrintStr
	mv	a0, s2
	ecall				# Affiche la fin de la phrase
	# ÉPILOGUE
	ld	ra, 0(sp)		
	ld	s0, 8(sp)		
	ld 	s1, 16(sp)		
	ld	s2, 24(sp)		
	addi 	sp, sp, 32	
	ret


# Recoit en parametre le joueur qui gagne et la matrice, affiche la matrice suivi du message de victoire 
# et quite le programme
joueurGagne:
	mv 	t0, a0			# Joueur
	mv	s2, a2			# Matrice
	mv 	a0, s2			
	jal	affichage		# Afficher la matrice
	la	a0, msgGagneP1
	mv	a1, t0
	la	a2, msgGagneP2
	jal 	prntStr			# Affiche le joueur gagnant
	jal 	fin


# Recoit en parametre le joueur qui perd, la colonne jouée ainsi que la matrice et 
# affiche le message de defaite et quite le programme
joueurPerd:
	mv 	s0, a0			# Joueur
	mv	s1, a1			# Colonne choisie
	mv	s2, a2			# Matrice
	
	addi 	s1, s1, 1		# s1 = colonne choisie + 1
	la	t1, msgLignePerd	# t1 = "........."
	add	t2, t1, s1		
	sb	s0, (t2)		# t1[s1] = joueur
	mv 	a0, t1			
	li	a7, PrintStr
	ecall				# Afficher la ligne du débordement
	
	mv 	a0, s2			
	jal	affichage		# Afficher la matrice

	la	a0, msgPerdP1		
	mv	a1, s0			
	la	a2, msgPerdP2		
	jal 	prntStr			# Afficher le joueur qui a perdu
	jal 	fin			


# Affiche un message d'erreur et quitte le programme
erreur : 
	li 	a7, 4			
	la 	a0, msgErr		
	ecall				# Affiche le message d'erreur
	li	a0, 1
	li	a7 Exit2
	ecall				# Quitter proprement


# Quitter le programme proprement
fin : 
	li 	a0, 0
	li 	a7, Exit		
	ecall				
	
