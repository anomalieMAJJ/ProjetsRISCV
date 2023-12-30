# TP1 -  Convertisseur entre les nombres romains et le décimal.
# Jessica Majeur, MAJJ 2651 9105 (groupe 20)
#
# Il n’y a pas de restrictions sur l’ordre ou le nombre des chiffres (normalement, les lettres ou les groupes 
# devraient apparaître dans l’ordre décroissant et la forme la plus courte devrait être être utilisée).

.data
	msgErr:	.asciz "err"

.eqv ReadChar, 12
.eqv PrintInt, 1
.eqv Exit, 10

.text
	li 	s8, 0			# Initialisation de la valeur totale du nombre romain (total)
	li 	s9, 0			# Initialisation de la lettre courrante (curr)
	li	s10, 0			# Initialisation de la lettre suivante (next)
	li	s0, '\n'		# Saut de ligne '\n' = fin de saisie
	li	s1, 'M'
	li	s2, 'D'
	li	s3, 'C'
	li	s4, 'L'
	li	s5, 'X'
	li	s6, 'V'
	li	s7, 'I'
	
loop:
	li 	a7, ReadChar		# Lecture des caractères
	ecall
	beq	a0, s0, reponse		# Fin de la boucle si le caractère est un saut de ligne '\n'
	j 	validation		# Vérifier que les caractères saisis sont valides

# Valide les caractères saisis par l'utilisateur
validation : 
	bne 	a0, s1, conversionD	# if char == 'M'
	li 	s10, 1000		# 	next = 1000
	j	comparaison
	
conversionD: 
	bne 	a0, s2, conversionC	# else if char == 'D'
	li 	s10, 500		# 	next = 500
	j	comparaison
	
conversionC : 
	bne 	a0, s3, conversionL	# else if char == 'C'
	li 	s10, 100		#	next = 100
	j	comparaison	

conversionL: 
	bne 	a0, s4, conversionX	# else if char == 'L'
	li 	s10, 50			#	next = 50
	j	comparaison	

conversionX:
	bne 	a0, s5, conversionV	# else lif char == 'X'
	li 	s10, 10			#	next = 10
	j	comparaison

conversionV:
	bne 	a0, s6, conversionI	# else if char == 'V'
	li 	s10, 5			#	next = 5
	j	comparaison

conversionI:
	bne 	a0, s7, erreur		# else if char == 'I'
	li 	s10, 1			#	next = 1
					# else erreur	

# Compare la valeur de la lettre courrante avec la suivante.
comparaison : 
	bge	s9, s10, addition	# if curr < next
	neg 	s9, s9			# 	curr = -curr
				
addition : 
	add	s8, s8, s9		# total += curr
	mv 	s9, s10			
	j 	loop

# Affiche la conversion du nombre romain en nombre décimal
reponse : 
	add	s8, s8, s9		# Additionne la dernière valeur saisie avant '\n' au total
	mv 	a0, s8			
	li 	a7, PrintInt		
	ecall				# Affiche la conversion du nombre romain en décimal
	j 	fin 			

# Affiche le message d'erreur
erreur : 
	li 	a7, 4			
	la 	a0, msgErr		
	ecall				# Affiche le message d'erreur
	j 	fin 			

# Quitter le programme proprement
fin : 
	li 	a0, 0
	li 	a7, Exit
	ecall
