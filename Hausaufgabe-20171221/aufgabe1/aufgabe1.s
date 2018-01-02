# v171213

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
    addi $sp, $sp, -4				# free space on stack
    sw $ra, 0($sp)					# space is for return value

    # save beginning of haystack
    move $t5, $a0				    # $t5 = $a0 email array
    # save len of needle
    move $t4, $a3					# $t4 = $a3 len of word array

    # calc end address of haystick and needle
    add $a1, $a1, $a0				# $a1 = end of email array
    add $a3, $a3, $a2				# $a3 = end of word array



haystick_loop:
    bge $a0, $a1, haystick_loop_end	# if len(email) == end of email array goto haystick_loop_end 
								# else
    move $t6, $a0					# $t6 = $a0 email array
    move $t7, $a2					# $t7 = $a2 word array
needle_loop:
    # load char from haystick
    lbu $t0, 0($t6)					# $t0 = byte code of first letter of email
    
    # load char from needle			
    lbu $t1, 0($t7)					# $t1 = byte code of first letter of word

    bne $t0, $t1, needle_loop_end		# if letter of email != letter of word goto needle_loop_end

    addi $t6, $t6, 1				# increment byte address by 1 ($t6 ++) email array
    addi $t7, $t7, 1				# increment byte address by 1 ($t7 ++) word array

    # reached end of needle
    bge $t7, $a3, found_str			# check if end of word is reached, if yes goto found_str

    # reached end of haystick
    bge $t6, $a1, found_nostr			# check if end of email is reached, if yes goto found_nostr

    j needle_loop
needle_loop_end:

    addi $a0, $a0, 1 				# go to next letter in email ($a0 ++)
    j haystick_loop
haystick_loop_end:

found_nostr:
    # prepare registers so found_str: produces -1
    li $t6, 0						# $t6 = 0
    li $t5, 0						# $t5 = 0
    li $t4, 1						# $t5 = 1

found_str:
    sub $v0, $t6, $t5				# $v0 = $t6 (adress of email array where same string was found) - $t5 (startaddress of email array)
    sub $v0, $v0, $t4				# $v0 = $v0 - $t4 (len of word array)


    # restore $ra from stack
    lw $ra, 0($sp)					# load stack pointer in $ra
    addi $sp, $sp, 4				# reset stack pointer
    jr $ra						# jump to return address

#########################################
# Vorgabe: read_email
#########################################
# $a0: buffer
# $v0: number of characters read

read_email:
    move $t0, $a0					# $t0 = $a0 (buffer)

    # read mail from disk
    li $v0, 13						# $v0 = 13
    la $a0, input_file				# copy email from main memory (RAM address) into $a0
    li $a1, 0						# $a1 = 0
    li $a2, 0						# $a2 = 0
    syscall						# syscall code: Open File

    # save fd
    move $t1, $v0					# $t1 = $v0 (contains file discribter)

    # read to buffer
    li $v0, 14						# $v0 = 14
    move $a0, $t1					# $a0 = $t1 (contains file discribter)
    move $a1, $t0 # address of buffer	# $a1 = $t0 (address of buffer)
    li $a2, 4096					# $a2 = 4096
    syscall						# Syscall code: Read from File

    move $t0, $v0					# $t0 = $v0 (numbers of characters read)

    # close file
    li $v0, 16						# $v0 = 16
    move $a0, $t1 # fd				# $a0 = $t1 (13)
    syscall						# Syscall code: Close File

    move $v0, $t0					# $v0 = $t0 (numbers of characters read) 
    #move $a0, $t0


    jr $ra


#########################################
# Aufgabe 1: E-Mail parsen
#########################################
# v0: relative position of subject
# v1: relative begin of body

parse_email:
    ### Register gemass Konventionen sichern
	addi $sp, $sp, -16
	sw $ra, 0($sp)
    sw $s0, 4($sp)
    sw $s1, 8($sp)
    sw $s2, 12($sp)
    

    ### E-Mail in Puffer einlesen (0.5 Punkte)	
	la $a0, email_buffer			# $a0 = 4096 byte / character
    jal read_email					# $v0 = number of characters
    move $s0, $v0					# $s0 = number of characters

    ### Position des Subjektes bestimmen (1 Punkt) 
    la $a0, email_buffer            # copy email from main memory (RAM address) into $a0 (haystack)
    move $a1, $s0                   # $a1 = number of characters (len of haystack)
    la $a2, header_subject          # copy address of header_subject ("Subject: ") into $a2 (needle)
    lw $a3, header_subject_length   # copy header_subject_length (9) into $a3 (len of needle)

    jal find_str

    move $s1, $v0					# $s1 = position of "Subject: "

    ### Position des Endes des Headers bestimmen (1 Punkt)
    la $a0, email_buffer            # copy email from main memory (RAM address) into $a0 (haystack)
    move $a1, $s0                   # $a1 = number of characters (len of haystack)
    la $a2, header_end              # copy address of header_end (.byte 13, 10, 13, 10) into $a2 (needle)
    
    lw $a3, header_end_length       # copy header_end_length (4) into $a3 (len of needle)
    
	
    jal find_str
    
    la $a2, header_subject
    #li $v0, 4
    #syscall 

    move $t0, $a2                   # $t7 = $a2 word array
    
    # load char from needle         
    lbu $a0, 0($t0)                 # $t1 = byte code of first letter of word
    li $v0, 11
    syscall
    
    addi $sp, $sp, -4
    sw $s3, 0($sp)

    move $s3, $a0

    lw $s3, 0($sp)
    addi $sp, $sp, 4
    #addi $t0, $t0, 1

    #lbu $a0, 0($t0)
    #li $v0, 11
    #syscall
    
    #addi $sp, $sp, -4
    #sw $s3, 0($sp)
    #move $s3, $a0

    #li $a0, 10
    #li $v0, 11
    #syscall 

    #move $t3, $s3
    #lbu $a0, 0($t3)
    #li $v0, 11
    #syscall

    #addi $t3, $t3, 1
    #lbu  $a0, 0($t3)
    #li $v0, 11
    #syscall




    
    move $s2, $v0					# $s1 = position of ".byte 13, 10, 13, 10"

    ### Rueckgabewerte bereitstellen (0.5 Punkte)
	move $v0, $s1
	addi $v0, $v0, 9				# add 9 to get position at the end of "Subject: "
    move $v1, $s2 
	addi $v1, $v1, 4				# add 9 to get position at the end of ".byte 13, 10, 13, 10"

    # Register wieder herstellen		
    lw $ra, 0($sp)
    lw $s0, 4($sp)
    lw $s1, 8($sp)
    lw $s2, 12($sp)
    addi $sp, $sp, 16
    
    jr $ra
	
#########################################
# Aufgabe 1 Ende
#########################################

#########################################
# data

.data

input_file: .asciiz "/home/ammer/Desktop/WiSe1718/RechnerOrg/Rorg_HA/Hausaufgabe-20171221/email1"
email_buffer: .space 4096
size: .word 0

header_subject: .asciiz "Subject: "
header_subject_length: .word 9

header_end: .byte 13, 10, 13, 10
header_end_length: .word 4

subject_pos: .asciiz "Position Subjekt: "
text_pos: .asciiz "Position Text: "

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

    jal parse_email 				# returns $v0 = offset of begin of header ("Einmalige ..." ohne Subject), $v1 = offset of begin of body ("Hochver...") 

    # Position Subjekt sichern
    move $s0, $v0					# $s0 = $v0 (offset of begin of header)
    # Position Ende Header sichern
    move $s1, $v1					# $s1 = $v1 (offset of begin of body)

    # Ausgabe
    la $a0, subject_pos
    li $v0, 4
    syscall						# Print String: from $a0 ("Position Subjekt: ")

    move $a0, $s0
    li $v0, 1
    syscall						#Print Integer: $a0 = $s0 (offset subject header)

    li $a0, 10
    li $v0, 11
    syscall						# Print Character: 10 (ascii Line feed)

    la $a0, text_pos
    li $v0, 4
    syscall						# Print String: from $a0 ("Position Text: ")				

    move $a0, $s1
    li $v0, 1
    syscall						# Print Integer: $a0 = $s1 (offset of begin of body)

    li $a0, 10
    li $v0, 11
    syscall						# Print Character: 10 (ascii Line feed)
    
    # Register wieder herstellen		
    lw $ra, 0($sp)
    lw $s0, 4($sp)
    lw $s1, 8($sp)
    addi $sp, $sp, 12
    jr $ra

#
# end main
#
