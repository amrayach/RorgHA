# v171215

#########################################
# Vorgabe: read_email
#########################################
# $a0: buffer
# $v0: number of characters read

read_email:
    move $t0, $a0

    # read mail from disk
    li $v0, 13
    la $a0, input_file
    li $a1, 0
    li $a2, 0
    syscall

    # save fd
    move $t1, $v0

    # read to buffer
    li $v0, 14
    move $a0, $t1
    move $a1, $t0 # address of buffer
    li $a2, 4096
    syscall

    move $t0, $v0

    # close file
    li $v0, 16
    move $a0, $t1 # fd
    syscall

    move $v0, $t0

    jr $ra

#########################################
# Vorgabe: write_email
#########################################
# $a0: buffer
# $a1: number of characters to write
# $a2: truncate file

write_email:
    addi $sp, $sp, -16
    sw $ra, 0($sp)
    sw $s0, 4($sp)						# $s0 = buffer
    sw $s1, 8($sp)						# $s1 = number of characters to write
    sw $s2, 12($sp)

    move $s0, $a0						# $s0 = buffer
    move $s1, $a1						# $s1 = number of characters to write

    # open file
    li $v0, 13
    la $a0, output_file

    bne $zero, $a2, write_email_trunc	# if $a2 (truncate file) != 0 (also True), goto write_email_trunc
    j write_email_notrunc
    write_email_trunc:
    li $a1, 0x241       # mode O_WRONLY | O_CREAT | O_TRUNC	-> $a1 = flags -> leerer File wird erstellt
    j write_email_else

    write_email_notrunc:
    li $a1, 0x441       # mode O_WRONLY | O_CREAT | O_APPEND -> $a1 = flags -> 

    write_email_else:
    li $a2, 0x1a4						# $a2 = mode
    syscall             # fd in $v0

    move $s2, $v0       # save fd

    li $v0, 15          # write to file
    move $a0, $s2						# $a0 = fd
    move $a1, $s0						# $a1 = $s0 = buffer
    move $a2, $s1						# $a2 = $s1 = number of characters to write
    syscall

    # close file
    li $v0, 16
    move $a0, $s2
    syscall

    lw $ra, 0($sp)
    lw $s0, 4($sp)
    lw $s1, 8($sp)
    lw $s2, 12($sp)
    addi $sp, $sp, 16
    jr $ra


#########################################
# Aufgabe 3: Ausgabe
#########################################
# a0: buffer
# a1: buffer length
# a2: relative position of subject
# a3: spam flag					# 1 if True

print_email:
    ### Register gemass Konventionen sichern
    addi $sp, $sp, -24
    sw $ra, 0($sp)
    sw $s0, 4($sp)				# $s0 = $a0 = buffer
    sw $s1, 8($sp)				# $s1 = $a1 = buffer length
    sw $s2, 12($sp)				# $s2 = $a2 = relative position of subject
	sw $s3, 16($sp)				# $s3 = spam_flag
	sw $s4, 20($sp)				# $s4 = spam_flag_length

    ### hier implementieren

	move $s0, $a0 				# $s0 = buffer
	move $s1, $a1				# $s1 = buffer length
	move $s2, $a2 				# $s2 = relative position of subject
	la $s3, spam_flag			# $s3 = address of spam_flag
	lw $s4, spam_flag_length	# $s4 = spam_flag_length

	# if $a3 == 0, print email normally
	bne $a3, $zero, isSpam
							# Argumtente: write_email
								# $a0: buffer
								# $a1: number of characters to write
								# $a2: truncate file
	# print email without changes
	addi $a2, $zero, 0			# set truncate file to false (zero)
	jal write_email				# print email ($a0 = buffer, $a1 = number of characters to write = buffer_length)
	j done						# no more action required
	
	isSpam:
	# if $a3 == 1, insert on position $a2 "[SPAM]" -> enlarge $a1 by 7 (including space)
	# 1. create file with first part of email (until relative position of subject)
	move $a0, $s0				# $a0 = address of buffer
	move $a1, $s2				# number of characters to write = relative position of subject
	addi $a2, $zero, 1			# set truncate file to true
	jal write_email

	# 2. append spam_flag "[SPAM]"
	move $a0, $s3				# $a0 = adress of spam_flag
	move $a1, $s4				# number of characters to write = spam_flag_length
	addi $a2, $zero, 0			# set truncate file to false
	jal write_email

	# 3. append rest of email
	add $s0, $s0, $s2			# calculate address of buffer without header
	move $a0, $s0				# $a0 = address of buffer
	sub $s1, $s1, $s2			# buffer lenght =  buffer lengh - relative position of subject
	move $a1, $s1				# number of characters to write = buffer lengh - relative position of subject
	addi $a2, $zero, 0			# set truncate file to false
	jal write_email

	done:
		
    ### gesicherte Register wieder herstellen
    lw $ra, 0($sp)
    lw $s0, 4($sp)
    lw $s1, 8($sp)
	lw $s2, 12($sp)
	lw $s3, 16($sp)
	lw $s4, 20($sp)
    addi $sp, $sp, 24
    jr $ra


#########################################
#

#
# data
#

.data

input_file: .asciiz "/home/johanna/Schreibtisch/Rechner Organisation/Hausaufgabe-20171220/email1"
output_file: .asciiz "output"
email_buffer: .space 4096

spam_flag: .asciiz "[SPAM] "
spam_flag_length: .word 7

#
# main
#

.text
.globl main

main:
    # Register sichern
    addi $sp, $sp, -12
    sw $ra, 0($sp)
    sw $s0, 4($sp)
    sw $s1, 8($sp)

    # E-Mail einlesen
    la $a0, email_buffer
    jal read_email

    la $a0, email_buffer

    # Groesse
    move $a1, $v0

    # Position des Subjekts
    li $a2, 292

    # Spam
    li $a3, 1

    # E-Mail ausgeben
    jal print_email

    # Register wieder herstellen
    lw $ra, 0($sp)
    lw $s0, 4($sp)
    lw $s1, 8($sp)
    addi $sp, $sp, 12
    jr $ra

#
# end main
#
