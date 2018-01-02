# v171218

#########################################
# Vorgabe: find_str
#########################################
# $a0: haystack
# $a1: len of haystack
# $a2: needle
# $a3: len of needle
# $v0: relative position of needle, -1 if not found

find_str:
    # save $ra on stack
    addi $sp, $sp, -4
    sw $ra, 0($sp)

    # save beginning of haystack
    move $t5, $a0
    # save len of needle
    move $t4, $a3

    # calc end address of haystick and needle
    add $a1, $a1, $a0
    add $a3, $a3, $a2

haystick_loop:
    bge $a0, $a1, haystick_loop_end

    move $t6, $a0
    move $t7, $a2
needle_loop:
    # load char from haystick
    lbu $t0, 0($t6)
    
    # load char from needle
    lbu $t1, 0($t7)

    bne $t0, $t1, needle_loop_end

    addi $t6, $t6, 1
    addi $t7, $t7, 1

    # reached end of needle
    bge $t7, $a3, found_str

    # reached end of haystick
    bge $t6, $a1, found_nostr

    j needle_loop
needle_loop_end:

    addi $a0, $a0, 1
    j haystick_loop
haystick_loop_end:

found_nostr:
    # prepare registers so found_str: produces -1
    li $t6, 0
    li $t5, 0
    li $t4, 1

found_str:
    sub $v0, $t6, $t5
    sub $v0, $v0, $t4


    # restore $ra from stack
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

#########################################
# Aufgabe 2: Spamfilter
#########################################
# $v0: Spamscore

spamfilter:
    ### Register gemaess Registerkonventionen sichern
	addi $sp, $sp, -36
	sw $ra, 0($sp)
    sw $s0, 4($sp) 				# badwords_buffer // in search_for_badwords $s0 = size of email_buffer
    sw $s1, 8($sp)				# len of badwords_buffer
	sw $s2, 12($sp)				# i -> counter for badwords_buffer
	sw $s3, 16($sp)				# address in heap memory for badword
	sw $s4, 20($sp)				# j -> counter for badword // in search_for_badwords $s4 = email_buffer
    sw $s5, 24($sp)             # address of heap mem of weight of badword
    sw $s6, 28($sp)             # len of badword
	sw $s7, 32($sp)				# Spamscore

	addi $s7, $zero, 0			# $s7 = sum of badwords_weight

    ### Badwords liegen im Puffer badwords_buffer
	la $s0, badwords_buffer			# $s0 = badwords_buffer
	lw $s1, badwords_size			# $s1 = len of badwords_buffer

    ### Der Text der E-Mail liegt im Puffer email_buffer
	#la $s2, email_buffer			# $s1 = email_buffer
	#lw $s3, size					# $s3 = len of email_buffer

    li $v0, 9                       # syscall allocate heap mem for badword when $v0 == 9
    li $a0, 30                      # number of bytes is in $a0 
    syscall
    move $s3, $v0                   # save the address of the allocated mem

    li $v0, 9                       # syscall allocate heap mem from badword weight when $v0 == 9
    li $a0, 15                      # number of bytes is in $a0
    syscall
    move $s5, $v0                   # save the address of the allocated mem
   
    ### Schleife ueber Bad words (wort1,gewicht1,wort2,gewicht2,...)
	add $s2, $zero, $zero		# $s4 = i = 0
	add $s4, $zero, $zero		# $s6 = j = 0

	### reset registers which were used in search_for_badwords for other stuff		
	reset_s_register:
		add $s4, $zero, $zero		# $s6 = j = 0
		la $s0, badwords_buffer			# $s0 = badwords_buffer
		lw $s1, badwords_size			# $s1 = len of badwords_buffer

        ### lese ein Wort		
		while: 

            bge $s2, $s1, endwhile	# goto endwhile if end of array is reached

			add $t0, $s0, $s2		# calculate address of badwords_buffer[i]			
			lb $a0, 0($t0)			# $a0 = badwords_buffer[i]
			
			jal isDigit				# if no digit $v0 = zero, else $v0 = 1
			bne $v0, $zero, isDigitTrue #
			jal isComma				# if no digit $v0 = zero, else $v0 = 1
			bne $v0, $zero, isCommaTrue	#

            add $t0, $s0, $s2		# calculate address of badwords_buffer[i]
			lb $t0, 0($t0)			# $t0 = badwords_buffer[i]

            add $t1, $s3, $s4       # calculate the address of the badword + j
            sb $t0, 0($t1)          # save the char at the right place 

			
			addi $s2, $s2, 1		# i++
			addi $s4, $s4, 1		# j++

			j while
			
        ### lese und konvertiere Gewicht
        isDigitTrue:

            add $t0, $s0, $s2       # calculate address of badwords_buffer[i]
            lb $t0, 0($t0)          # $t0 = badwords_buffer[i]

            add $t1, $s5, $s4       # calculate address of weight of badword    
            addi $t0, $a0, -48      # convert from ASCII to int 
            sb $t0, 0($t1)          # save the ints in the heap mem
              
            addi $s2, $s2, 1            # i++
            addi $s4, $s4, 1            # j++
            add $t0, $s0, $s2       	# calculate address of badwords_buffer[i]           
            lb $a0, 0($t0)         		# $a0 = badwords_buffer[i]
            jal isDigit             	# if no digit $v0 = zero, else $v0 = 1
            bne $v0, $zero, isDigitTrue # 

			addi $s4, $s4, -1			# j-- set back j to correct value (has been incremented before j)
            add $t0, $zero, $zero       # int(badword_weight) = 0 
            move $t1, $s4               # $t1 = j
            addi $t2, $zero, 10         # $t2 = 10 (Decimal Basis)

            convert_to_int:
				blt $s4, $zero, end_convert_to_int # if j == 0 goto end_convert_to_int
                
				add $t3, $s4, $s5       # calculate address from &badword_weight[j]
                lb $t4, 0($t3)          # $t4 = badword_weight[j]
				
                sub $t5, $t1, $s4       # exp = $t1 - j ($t1 is always == initial value of j)
                addi $t6, $zero, 1      # $t6 = 10^exp
                    exponent:

                        beq $t5, $zero, end_exponent    # if exp == 0 break
                        mul $t6, $t6, $t2               # $t6 = $t6 * 10
						addi $t5, $t5, -1				# exp--

						j exponent
                    end_exponent:
				addi $t7, $zero, 0						# $t7 = 0
				mul $t7, $t6, $t4 						# $t7 = result of ascii nr * basis^exp
				add $t0, $t0, $t7						# int(badword_weight) = int(badword_weight) + (ascii nr * basis^exp)

				addi $s4, $s4, -1						# j--
				j convert_to_int

            end_convert_to_int:

			addi $t1, $s5, 0							# get address where int badword_weight shall be stored	
			sw $t0, 4($t1)								# store badword_weight

            j search_for_badwords
		
        isCommaTrue:

            add $t0, $s3, $s4           # calculate the address of badword
            sb $zero, 0($t0)            # append \0 at the end of each badword to know where it ends
			move $s6, $s4				# $s6 = $s4 = j = len of badword

            add $s4, $zero, $zero       # $s6 = j = 0 set back to zero
            addi $s2, $s2, 1            # i++
            
            j while

        ### suche alle Vorkommen des Wortes im Text der E-Mail und addiere Gewicht
		search_for_badwords:
			la $s4, email_buffer		# load emai_buffer into $s4
			lw $s0, size				# load size of email_buffer into $s7
			addi $v0, $zero, 0			# initialize $v0 = 0
			
			while_find_str:
				#blt $v0, $zero, end_while_find_str		# no word was found, goto while to find next word

				add $s4, $s4, $v0						# move address of email_buffer by number of position of badword ($v0)
				add $s4, $s4, $s6						# add len of badword ($s6)

				# check that new email_buffer address is not out of bound
				la $t0, email_buffer
				lw $t1, size
				add $t0, $t0, $t1
				bge $s4, $t0, end_while_find_str
				
				sub $s0, $s0, $v0						# adjust size of email_buffer by number of position of badword ($v0)
				sub $s0, $s0, $s6						# sublen of badword ($s6)

				blt $s7, $zero, end_while_find_str		# no word was found, goto while to find next word

				move $a0, $s4							# $a0: haystack
				move $a1, $s0							# $a1: len of haystack
				move $a2, $s3							# $a2: needle
				move $a3, $s6							# $a3: len of needle

				jal find_str

				blt $v0, $zero, end_while_find_str		# no word was found, goto while to find next word

				lw $t2, 4($s5)							# load badword_weight
				add $s7, $s7, $t2						# add badword_weight to total spamscore
				
				j while_find_str

			end_while_find_str:
				
			j reset_s_register

		end_search_for_badwords:

		endwhile:

    ### Rueckgabewert setzen
	move $v0, $s7					
    ### Register wieder herstellen
	
	lw $ra, 0($sp)
    lw $s0, 4($sp) 				# badwords_buffer
    lw $s1, 8($sp)				# len of badwords_buffer
	lw $s2, 12($sp)				# i
	lw $s3, 16($sp)				# badword
	lw $s4, 20($sp)				# j -> counter for badword
	lw $s5, 24($sp)				# 
	lw $s6, 28($sp)				# len of badword
	lw $s7, 32($sp)				# Spamscore
    addi $sp, $sp, 36

    jr $ra

#########################################
#Eigene Funktion: isDigit
#########################################
# $a0: char to check
# $v0: 1 if argument is digit, otherwise 0
isDigit:
	li $t0, 48					# ASCII Tabelle: 48 = Ziffer
	li $t1, 57					# ASCII Tabelle:  bis 57 = Ziffern
	
	move $v0, $zero				# $v0 = zero, Null speichern, da dies zurück gegeben wird, wenn keine Zahl
	 
    blt $a0, $t0, failD			# wenn kleiner als 48, springe zu fail
	bgt $a0, $t1, failD			# wenn größer als 57, springe zu fail
	addi $v0, $v0, 1			# $v0 = 1, because between 48-57

	failD:
		jr $ra

#########################################
#Eigene Funktion: isComma
#########################################
# $a0: char to check
# $v0: 1 if argument is comma, otherwise 0
isComma:
	li $t0, 44					# ASCII Tabelle: 44 = Comma
	
	move $v0, $zero				# $v0 = zero, Null speichern, da dies zurück gegeben wird, wenn keine Zahl
	bne $a0, $t0, failC			# wenn kleiner als 48, springe zu fail
	addi $v0, $v0, 1			# $v0 = 1, because between 48-57

	failC:
		jr $ra

#########################################
#

#
# data
#

.data

email_buffer: .asciiz "Hochverehrte Empfaenger,\r\n\r\nbei dieser E-Mail handelt es sich nicht um Spam sondern ich moechte Ihnen\r\nvielmehr ein lukratives Angebot machen: Mein entfernter Onkel hat mir mehr Geld\r\nhinterlassen als in meine Geldboerse passt. Ich muss Ihnen also etwas abgeben.\r\nVorher muss ich nur noch einen Spezialumschlag kaufen. Senden Sie mir noch\r\nheute BTC 1,000 per Western-Union und ich verspreche hoch und heilig Ihnen\r\nalsbald den gerechten Teil des Vermoegens zu vermachen.\r\n\r\nHochachtungsvoll\r\nAchim Mueller\r\nSekretaer fuer Vermoegensangelegenheiten\r\n"

size: .word 550

badwords_buffer: .asciiz "Spam,5,Geld,1,ROrg,0,lukrativ,3,Kohlrabi,10,Weihnachten,3,Onkel,7,Vermoegen,2,Brief,4,Lotto,3"
badwords_size: .word 93

spamscore_text: .asciiz "Der Spamscore betraegt: "

#
# main
#

.text
.globl main

main:
    # Register sichern
    addi $sp, $sp, -8
    sw $ra, 0($sp)
    sw $s0, 4($sp)


    jal spamfilter
    move $s0, $v0


    li $v0, 4
    la $a0, spamscore_text
    syscall
    
    move $a0, $s0
    li $v0, 1
    syscall

    li $v0, 11
    li $a0, 10
    syscall


    # Register wieder herstellen
    lw $ra, 0($sp)
    lw $s0, 4($sp)
    addi $sp, $sp, 8
    jr $ra

#
# end main
#
