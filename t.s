.section .data
s1: .asciz "void"
s2: .asciz "void asdf"

.section .text
.global _start
_start:
        enter $8, $0
    
        movq $s1, %rdi
        call is_char
        je crash

        leave
        movq $60, %rax
        movq $1, %rdi
        syscall
    crash:
        movq (%rax), %rax

loopii:
    enter $0, $0
    movq $10, %rcx
        xor %rax, %rax
    begin:
        inc %rax
        loopnz  begin
    leave
    ret



// in  rdi: char *character
// out: Conditional flag. je if equal jne if not equal
.global is_char
.type is_char, @function
is_char:
        movb (%rdi), %bl
        andb $223, %bl # 223 -> 1101 1111
        # Trick to remove the 6th bit
        # We now only have to compare twice
        # In the range [65; 90]
        cmpb $65, %bl
        setge %al
        cmpb $90, %bl
        setle %bl
        cmpb %bl, %al
        ret

# v -> 118 -> 01110110
# V ->  86 -> 01010110
#      
