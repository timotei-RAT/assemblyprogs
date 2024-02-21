include win64.inc               
option win64:0111b
option literals:on

ptrELEM TYPEDEF ptr
ptrBYTE TYPEDEF ptr
ELEM STRUCT
    prev ptrELEM NULL
    next ptrELEM NULL
    data ptrBYTE NULL
ELEM ENDS

ptrLIST TYPEDEF ptr
LIST STRUCT
    first ptrELEM NULL
    activ ptrELEM NULL
    last  ptrELEM NULL
LIST ENDS

input proto (ptrBYTE) :ptrBYTE
getVK proto (WORD)

PrintList proto :ptrLIST
AddFirst proto :ptrLIST
AddLast proto :ptrLIST
AddAbove proto :ptrLIST
AddBelow proto :ptrLIST
DeleteActiv proto :ptrLIST
DeleteList proto :ptrLIST

.data
    hStdOut HANDLE ?              
    hStdIn HANDLE ?               
    list LIST {NULL, NULL, NULL}

.code                           
  main proc uses rbx             
    mov hStdOut, GetStdHandle(STD_OUTPUT_HANDLE)
    .if (hStdOut == INVALID_HANDLE_VALUE)
        printf("Error reading Standard Output Handle\n")
        exit(-1)
    .endif
    mov hStdIn, GetStdHandle(STD_INPUT_HANDLE)
    .if (hStdIn == INVALID_HANDLE_VALUE)
        printf("Error reading Standard Input Handle\n")
        exit(-1)
    .endif
    PrintList(&list)
    .repeat
        mov bx, getVK()
        .switch bx
            .case VK_F1
                AddFirst(&list)
                PrintList(&list)
            .case VK_F2
                AddLast(&list)
                PrintList(&list)
            .case VK_F3
                AddAbove(&list)
                PrintList(&list)
            .case VK_F4
                AddBelow(&list)
                PrintList(&list)
            .case VK_DELETE
                DeleteActiv(&list)
                PrintList(&list)
            .case VK_F8
                DeleteList(&list)
                PrintList(&list)
            .case VK_UP
                mov rax, list.activ
                .if rax != NULL && [rax].ELEM.prev != NULL
                    mov rax, [rax].ELEM.prev
                    mov list.activ, rax
                .endif
                PrintList(&list)
            .case VK_DOWN
                mov rax, list.activ
                .if rax != NULL && [rax].ELEM.next != NULL
                    mov rax, [rax].ELEM.next
                    mov list.activ, rax
                .endif
                PrintList(&list)
        .endsw
    .until bx == VK_ESCAPE
    DeleteList(&list)
    exit(0)                         
    ret
  main endp                         

PrintList proc uses rbx rsi @list:ptrLIST
    mov rsi, @list
    system("cls")
    SetConsoleTextAttribute(hStdOut, 0x4E)           
    printf("F1=AddTop F2=AddBottom F3=AddAbove F4=AddBelow DEL=Delete F8=DelList UP/DOWN=navigate ESC=EXIT\n")
    SetConsoleTextAttribute(hStdOut, 0x0E)         
    printf("   Prev:            Activ:           Next:            Text F:%p A:%p L:%p\n", list.first, list.activ, list.last)
    mov rbx, [rsi].LIST.first                     
    .if rbx == NULL
        SetConsoleTextAttribute(hStdOut, 0x0C)     
        printf("*** lista vida ***\n")
    .endif
    .while rbx != NULL
        .if rbx == [rsi].LIST.activ
            SetConsoleTextAttribute(hStdOut, 0xF0) 
        .else
            SetConsoleTextAttribute(hStdOut, 0x0F) 
        printf("   %p %p %p '%s'\n", [rbx].ELEM.prev, rbx, [rbx].ELEM.next, [rbx].ELEM.data)
        mov rbx, [rbx].ELEM.next
    .endw
    SetConsoleTextAttribute(hStdOut, 0x07)          
    ret
PrintList endp

input proc uses rbx @msg:ptrBYTE
  local _buffer[101]:BYTE
  local _read:DWORD
    printf(@msg)                            

    ReadConsole(hStdIn, &_buffer, 100, &_read, NULL)
  
    lea  rax, _buffer                      
    mov  ebx, _read                       
    mov  byte ptr [rax+rbx-2], 0           
    dec  rbx                               
    mov  rbx, malloc(rbx)                  
    strcpy(rbx, &_buffer)                 
    mov  rax, rbx                           
    ret
input endp

AddFirst proc uses rbx rsi @list:ptrLIST
    mov rsi, @list
    mov rbx, malloc(sizeof(ELEM))          
    .if rbx
        mov [rbx].ELEM.data, input("val first elem: ")
        mov rax, [rsi].LIST.first          
        .if rax == NULL                    
            mov [rbx].ELEM.prev, NULL      
            mov [rbx].ELEM.next, NULL       
            mov [rsi].LIST.first, rbx      
            mov [rsi].LIST.activ, rbx      
            mov [rsi].LIST.last, rbx       
        .else                               
            mov [rbx].ELEM.prev, NULL       
            mov [rbx].ELEM.next, rax       
            mov [rax].ELEM.prev, rbx        
            mov [rsi].LIST.first, rbx       
        .endif                              
    .else
        printf("mem alloc error!")
    .endif
    ret
AddFirst endp

AddLast proc uses rbx rsi @list:ptrLIST
    mov rsi, @list
    mov rbx, malloc(sizeof(ELEM))          
    mov [rbx].ELEM.data, input("val last elem: ")
    .if rbx
        mov rcx, [rsi].LIST.last           
        .if rcx == NULL                    
            mov [rbx].ELEM.prev, NULL      
            mov [rbx].ELEM.next, NULL       
            mov [rsi].LIST.first, rbx      
            mov [rsi].LIST.activ, rbx       
            mov [rsi].LIST.last, rbx        
        .else                               
            mov [rbx].ELEM.next, NULL      
            mov [rbx].ELEM.prev, rcx       
            mov [rcx].ELEM.next, rbx       
            mov [rsi].LIST.last, rbx       
        .endif                            
    .else
        printf("mem alloc error!")
    .endif
    ret
AddLast endp

AddAbove proc uses rbx rsi @list:ptrLIST
    mov rsi, @list
    mov rbx, malloc(sizeof(ELEM))          
    .if rbx
        mov [rbx].ELEM.data, input("value upper elem: ")
        mov rcx, [rsi].LIST.activ        
        .if rcx == NULL                   
            mov [rbx].ELEM.prev, NULL      
            mov [rbx].ELEM.next, NULL      
            mov [rsi].LIST.first, rbx      
            mov [rsi].LIST.activ, rbx      
            mov [rsi].LIST.last, rbx       
        .else                               
            mov rax, [rcx].ELEM.prev       
            mov [rcx].ELEM.prev, rbx       
            mov [rbx].ELEM.next, rcx       
            mov [rbx].ELEM.prev, rax      
            .if rax != NULL                
                mov [rax].ELEM.next, rbx    
            .else                          
                mov [rsi].LIST.first, rbx  
            .endif
        .endif                             
    .else
        printf("mem alloc err!")
    .endif
    ret
AddAbove endp

AddBelow proc uses rbx rsi @list:ptrLIST
    mov rsi, @list
    mov rbx, malloc(sizeof(ELEM))          
    .if rbx
        mov [rbx].ELEM.data, input("val lower element ")
        mov rax, [rsi].LIST.activ         
        .if rax == NULL                    
            mov [rbx].ELEM.prev, NULL       
            mov [rbx].ELEM.next, NULL      
            mov [rsi].LIST.first, rbx       
            mov [rsi].LIST.activ, rbx      
            mov [rsi].LIST.last, rbx       
        .else                              
            mov rcx, [rax].ELEM.next       
            mov [rax].ELEM.next, rbx        
            mov [rbx].ELEM.prev, rax       
            mov [rbx].ELEM.next, rcx     
            .if rcx != NULL                
                mov [rcx].ELEM.prev, rbx   
            .else                           
                mov [rsi].LIST.last, rbx   
            .endif
        .endif                             
    .else
        printf("mem alloc err!")
    .endif
    ret
AddBelow endp

DeleteActiv proc uses rbx rsi @list:ptrLIST
    mov rsi, @list
    mov rbx, [rsi].LIST.activ          
    .if rbx != NULL                    
        mov rax, [rbx].ELEM.prev       
        mov rcx, [rbx].ELEM.next       
        .if rax != NULL                 
            mov [rax].ELEM.next, rcx    
            mov [rsi].LIST.activ, rax  
        .else                           
            mov [rsi].LIST.first, rcx   
            mov [rsi].LIST.activ, rcx   
        .endif                          
        .if rcx != NULL                 
            mov [rcx].ELEM.prev, rax   
            mov [rsi].LIST.activ, rcx  
        .else                          
            mov [rsi].LIST.last, rax    
            mov [rsi].LIST.activ, rax   
        .endif
        free([rbx].ELEM.data)          
        free(rbx)                      
    .endif                            
    ret
DeleteActiv endp

DeleteList proc uses rbx rsi @list:ptrLIST
    mov rsi, @list
    mov rbx, [rsi].LIST.first          
    .while rbx != NULL                
        free([rbx].ELEM.data)         
        mov rcx, rbx                  
        mov rbx, [rbx].ELEM.next        
        free(rcx)                     
    .endw                              
    mov [rsi].LIST.first, rbx          
    mov [rsi].LIST.activ, rbx          
    mov [rsi].LIST.last, rbx           
    ret
  DeleteList endp

getVK proc
    LOCAL lpBuffer:INPUT_RECORD
    LOCAL lpRead:DWORD
    ReadConsoleInput(hStdIn, addr lpBuffer, 1, addr lpRead)
    .if (lpBuffer.EventType == KEY_EVENT) && (lpBuffer.KeyEvent.bKeyDown == 1)
        mov ax, lpBuffer.KeyEvent.wVirtualKeyCode
    .else
        xor ax, ax
    .endif
    ret
getVK endp

end
