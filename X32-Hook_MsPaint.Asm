.386
.model flat, stdcall  ;32 bit memory model
option casemap :none  ;case sensitive

include Hook_MsPaint.inc

.code

start:
        ;call InitInjectCode
        
	invoke GetModuleHandle,NULL
	mov		hInstance,eax

    invoke InitCommonControls
	invoke DialogBoxParam,hInstance,IDD_DIALOG1,NULL,addr DlgProc,NULL
	invoke ExitProcess,0

;########################################################################

;<<<<<<<<<<<<<<<<<<<<
;   ���ڹ��̺���
;>>>>>>>>>>>>>>>>>>>>
DlgProc proc hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM

	mov		eax,uMsg
	.if eax==WM_INITDIALOG

	.elseif eax==WM_COMMAND
            .if wParam == IDC_BTN_HOOK
                invoke OnBtnHook
                
            .endif
            
	.elseif eax==WM_CLOSE
		invoke EndDialog,hWin,0
	.else
		mov		eax,FALSE
		ret
	.endif
	mov		eax,TRUE
	ret

DlgProc endp


;<<<<<<<<<<<<<<<<<<<<
;   Զ��ע�����
;>>>>>>>>>>>>>>>>>>>>
Remote_Begin:
    ;�ض�λ
    call $ + 5
    Relocate_Next:
    pop ebx
    sub ebx, Relocate_Next
    
    ;�����ض�λ
    ;mov [ebx + offset g_dwRelocate], ebx
    
    ;��ȡCreateFile����ʵ��ַ
    ;call  [ebx + offset GetCreateFileAddr]
    ;lea eax, offset GetCreateFileAddr
    ;lea eax, offset GetFunAddr
    ;add eax, ebx
    ;call  eax
    
    
    ;��ȡ��Ҫ�ĺ�����ַ
    lea eax, offset  GetFunAddr
    add eax, ebx
    call  eax
    .if eax == 0
            or eax, -1  ;�߳��˳� �˳�����-1
            ret
    .endif
 
    ;����ƫ�ƣ�HOOK CreateFile
    
    ;�ض�λ
    call @f
    @@:
    Lable_Relocate:
    pop ebx
    mov edi, ebx            ;���涨λ��ַ�����ڼ���HookApi  ��CallBack
    sub ebx, offset @b
    
    ;Hook API
    lea eax, offset HookApi
    add eax, ebx
    call eax
    .if eax == 0
        or eax, -1
        ret
    .endif
    
    ;ע����ɣ�Զ���߳��˳�
    or eax, 0
    ret
    ;jmp [ebx + g_pfnCreateFile + 5]
    
    
    ;==============CallBack Begin===============
    ;����CreateFile��������
    Lable_HookCallBack:

    ;����Ĵ�������
    pushad
    
    ;�ض�λ
    call @f
    @@:
    pop eax
 
    ;�����ض�λƫ��
    mov ebx, eax
    sub ebx, offset @b
    
    mov eax, [ebx + g_bIsHook]
    .if eax == TRUE
        popad
                    
        ;���CreateFile���ص�ַ
        pop eax
        
        ;�ָ�HOOK�޸ĵĴ���
        push ebp
        mov ebp, esp
        jmp eax

    .endif
    
    ;���ΪHOOK ����
    mov [ebx + g_bIsHook], TRUE
    
    
    ;CALL CreateLog
    lea eax, offset CreateLog
    add eax, ebx
    call eax
    .if eax == INVALID_HANDLE_VALUE
        or eax, -1
        ret
    .endif
    ;�ض�λ
    call @f
    @@:
    pop ebx
    sub ebx, offset @b  
    
    mov [ebx + offset g_hFileHandle], eax
    
    ;����д��־
    lea eax, offset  WriteLog
    add eax, ebx
    call  eax
    
    ;�ر��ļ�
    mov eax, [ebx + g_hFileHandle]
    push eax
    call  [ebx + offset g_pfnCloseHandle]
    
    popad
    ;����CreateFile����
    ;jmp [ebx + g_pfnCreateFile + 5]
    ;ret
    ;��÷��ص�ַ
    pop eax
    
    ;�ָ�HOOK�޸ĵĴ��룬ת�����̻�CreateFile
    push ebp
    mov ebp, esp
    jmp eax
    
    
    ;==============CallBack End===============
    
    ;.data
    ;g_dwRelocate         DWORD 0    ;�ض�λ�ֽ���
    g_hFileHandle         HANDLE  0
    
    g_pfnLoadLibrary    DWORD 0
    g_pfnGetProcAddr  DWORD 0
    g_pfnCreateFile       DWORD 0
    g_pfnWriteFile         DWORD 0
    g_pfnSetFilePointer DWORD 0
    g_pfnCloseHandle   DWORD 0
    g_pfnGetLocalTime DWORD 0
    g_pfnWsprintf         DWORD 0
    g_pfnVirtualProtect DWORD 0
    
    g_bIsHook               DWORD FALSE
    
    g_bJmp  db 0E8H

    g_szCR_LF   db 0Dh, 0AH, 0      ;�س�����
    
    g_szCreateFile db 'CreateFileW', 0
    ;g_szCreateFileW db 'C', 0, 'r', 0, 'e', 0, 'a', 0, 't', 0, 'e', 0, 'F', 0, 'i', 0, 'l', 0, 'e', 0, 'W', 0, 0, 0
    g_szWriteFile  db 'WriteFile', 0
    g_szSetFilePointer db 'SetFilePointer', 0
    g_szCloseHandle db 'CloseHandle', 0
    g_szGetLocalTime db 'GetLocalTime', 0
    g_szWsprintf   db 'wsprintfA', 0
    g_szVirtualProtect db 'VirtualProtect', 0
    
    g_szKernel32         db 'Kernel32.dll', 0
    ;g_szKernel32W db 'K', 0, 'e', 0, 'r', 0, 'n', 0, 'e', 0, 'l', 0, '3', 0, '2', 0, '.', 0, 'd', 0, 'l', 0, 'l', 0, 0, 0
    g_szUser32 db 'User32.dll', 0
    
    g_szFileNameA db 'Log.txt', 0
    g_szFileNameW db 'c', 0, ':', 0, '/', 0, 'L', 0, 'o', 0, 'g', 0, '.', 0, 't', 0, 'x', 0, 't', 0, 0, 0
    
    ;��/�� ʱ-��-��
    g_szFmtStr   db '%02d/%02d %02d:%02d:%02d    ', 0
    ;.dataEnd
    
    HookApi proc
        LOCAL @oldProtect: DWORD
        ;invoke VirtualProtect, addr Remote_Begin, Remote_End - Remote_Begin, \
        ;                                PAGE_EXECUTE_READWRITE, addr @oldProtect
        
        lea eax, [@oldProtect]
        push  eax
        push  PAGE_EXECUTE_READWRITE
        push  5
        mov eax, [ebx + g_pfnCreateFile]
        push eax
        call [ebx + g_pfnVirtualProtect]
        .if eax == 0
            ret
        .endif
 
        ;дE9
        mov ecx, [ebx + g_pfnCreateFile]
        mov al, [ebx + g_bJmp]
        mov byte ptr [ecx], al
    
        ;д��ַ
        ;ƫ�Ƶ�ַ = Ŀ���ַ - API ��ַ - 5
        mov eax, edi        ;�ض�λ��ַ
        add eax, Lable_HookCallBack - Lable_Relocate ;��ʵ�����ַ
        ;mov edx, [ebx + g_pfnCreateFile]    ;API ��ַ
        mov edx, ecx     ;API ��ַ
        sub eax, edx            ;
        sub eax, 5
        mov [ecx + 1], eax

        ret
    HookApi endp
    
     ;<<<<<<<<<<<<<<<<<<<<
    ;   ������־�ļ�
    ;   ����ֵ�� �ɹ�/ʧ��
    ;>>>>>>>>>>>>>>>>>>>>
    CreateLog proc
        ;Call �����ļ�
        
        ;����־λ����´ν���Ϊ�ݹ鷽ʽ���룬��ֱ���˳�
        mov [ebx + g_bIsHook], TRUE
        
        push NULL                                       ;�ļ�ģ��
        push FILE_ATTRIBUTE_NORMAL     ;�ļ�����
        push OPEN_ALWAYS                       ;��δ���
        push NULL                                       ;��ȫ����
        push FILE_SHARE_READ                  ; �򿪷�ʽ��  ������
        push 0C0000000H                           ;GENERIC_READ|GENERIC_WRITE
        lea eax, [ebx + offset g_szFileNameW]       
        push eax                                          ; �ļ�·��  ���ļ�·�� + �ļ�����
        
        ;lea eax, offset g_pfnCreateFile
        mov eax, [ebx + offset g_pfnCreateFile]
        ;add eax, ebx
        call eax
        .if eax == INVALID_HANDLE_VALUE
            and eax, 0
            ret
        .endif
        
        ;�ض�λ
        call @f
        @@:
        pop ebx
        sub ebx, offset @b        
        
        ;��־������
        mov [ebx + g_bIsHook], FALSE
        
        ret
    CreateLog endp
    
    ;<<<<<<<<<<<<<<<<<<<<
    ;   д��־
    ;   ����ֵ�� �ɹ�/ʧ��
    ;>>>>>>>>>>>>>>>>>>>>
    WriteLog proc   
        LOCAL @szTime[MAXBYTE]: BYTE
        LOCAL @dwLen: DWORD
        LOCAL @dwOutLen: DWORD
        
        ;push ebp
        ;mov ebp, ebx
        
        ;�ƶ��ļ�ָ��        
        push FILE_END ;�ļ�β��
        push NULL
        push NULL
        mov eax, offset g_hFileHandle   ;�ļ����
        add eax, ebx
        push [eax]
        
        call [ebx + offset g_pfnSetFilePointer]
        .if eax == INVALID_SET_FILE_POINTER
            and eax, 0
            ret
        .endif
        
        ;��ȡʱ��
        lea eax, @szTime
        push eax
        lea eax, offset  GetTime
        add eax, ebx
        call  eax
        ;call [ebp + GetTime]
        
        ;д��ʱ��
        ;�ض�λ
        call @f
        @@:
        pop ebx
        sub ebx, offset @b  
        
        ;����ʱ���ַ�������
        lea eax, [@szTime]
        push eax
        
        lea eax, [StrLen]
        add eax, ebx
        call eax
        mov @dwLen, eax
        
        ;д�ļ�
        push NULL                       ;
        lea eax, [@dwOutLen]    
        push eax                            ;����д�˶����ֽ�
        push @dwLen                 ;��Ҫд�೤
        lea eax, [@szTime]
        push eax                            ;��������ַ
        mov eax, [ebx + offset g_hFileHandle]
        push eax                            ;�ļ����
        
        call [ebx + offset g_pfnWriteFile]
        
        ;��ȡջ�еĲ���
        mov eax, [ebp + 30H]
        push eax
        lea eax, [BstrLen]
        add eax, ebx
        call eax
        mov @dwLen, eax
        
        ;EBP+30H
        
        ;д�����
        push NULL                       ;
        lea eax, [@dwOutLen]    
        push eax                            ;����д�˶����ֽ�
        push @dwLen                 ;��Ҫд�೤
        mov eax, [ebp + 30H]
        push eax                            ;��������ַ
        mov eax, [ebx + offset g_hFileHandle]
        push eax                            ;�ļ����
        
        call [ebx + offset g_pfnWriteFile]
        
        ;д��س�����
        push NULL                       ;
        lea eax, [@dwOutLen]    
        push eax                            ;����д�˶����ֽ�
        push 2                 ;��Ҫд�೤
        lea eax, [offset g_szCR_LF]
        add eax, ebx
        push eax                            ;��������ַ
        mov eax, [ebx + offset g_hFileHandle]
        push eax                            ;�ļ����
        
        call [ebx + offset g_pfnWriteFile]
        ;�ύ�ļ�
        
        ret
    WriteLog endp
    
;    GetAppCreateFileAddr proc
;        
;        mov esi, 01001200H
;        mov eax, [esi]
;        mov [ebx + g_pfnCreateFile], eax
;        
;        ret
;    GetAppCreateFileAddr endp
    
    GetFunAddr proc 
        LOCAL @hKernelMod: HMODULE 
        LOCAL @hUserMod: HMODULE
        
        ;��ȡKernelģ���ַ
        lea eax, [ebx + offset g_szKernel32]
        push eax
        
        mov eax, [ebx + offset g_pfnLoadLibrary]
        ;add eax, ebx
        call eax
        .if eax == 0
            ret
        .endif
        mov @hKernelMod, eax
        
         ;��ȡUser32ģ���ַ
        lea eax, [ebx + offset g_szUser32]
        push eax
        
        mov eax, [ebx + offset g_pfnLoadLibrary]
        ;add eax, ebx
        call eax
        .if eax == 0
            ret
        .endif
        mov @hUserMod, eax
        
        ;��ȡCreateFile������ַ
        lea eax, [ebx + offset g_szCreateFile]
        push eax
        
        mov eax, @hKernelMod
        push eax
        mov eax, [ebx + offset g_pfnGetProcAddr]
        call eax
        .if eax == 0
            ;invoke GetLastError
            ;and eax, 0
            ret
        .endif
        mov [ebx + offset g_pfnCreateFile], eax
        
        ;��ȡWriteFile������ַ
        lea eax, [ebx + offset g_szWriteFile]
        push eax
        
        mov eax, @hKernelMod
        push eax
        mov eax, [ebx + offset g_pfnGetProcAddr]
        call eax
        .if eax == 0
            ;invoke GetLastError
            ;and eax, 0
            ret
        .endif
        mov [ebx + offset g_pfnWriteFile], eax
        
        ;��ȡSetFilePointer������ַ
        lea eax, [ebx + offset g_szSetFilePointer]
        push eax
        
        mov eax, @hKernelMod
        push eax
        mov eax, [ebx + offset g_pfnGetProcAddr]
        call eax
        .if eax == 0
            ;invoke GetLastError
            ;and eax, 0
            ret
        .endif
        mov [ebx + offset g_pfnSetFilePointer], eax

        ;��ȡCloseHandle������ַ
        lea eax, [ebx + offset g_szCloseHandle]
        push eax
        
        mov eax, @hKernelMod
        push eax
        mov eax, [ebx + offset g_pfnGetProcAddr]
        call eax
        .if eax == 0
            ret
        .endif
        mov [ebx + offset g_pfnCloseHandle], eax

        
        ;��ȡGetLocalTime������ַ
        lea eax, [ebx + offset g_szGetLocalTime]
        push eax
        
        mov eax, @hKernelMod
        push eax
        mov eax, [ebx + offset g_pfnGetProcAddr]
        call eax
        .if eax == 0
            ret
        .endif
        mov [ebx + offset g_pfnGetLocalTime], eax
        
        ;��ȡVirtualProtect������ַ
        lea eax, [ebx + offset g_szVirtualProtect]
        ;lea eax, [ebx + offset g_szGetLocalTime]
        push eax
        
        mov eax, @hKernelMod
        push eax
        mov eax, [ebx + offset g_pfnGetProcAddr]
        call eax
        .if eax == 0
            ;invoke GetLastError
            ;and eax, 0
            ret
        .endif
        mov [ebx + offset g_pfnVirtualProtect], eax
        
        
        ;��ȡwsprintf������ַ
        lea eax, [ebx + offset g_szWsprintf]
        push eax
        
        mov eax, @hUserMod
        push eax
        mov eax, [ebx + offset g_pfnGetProcAddr]
        call eax
        .if eax == 0
            ret
        .endif
        mov [ebx + offset g_pfnWsprintf], eax
        
        
        ;ж��Lib
        ;invoke FreeLibrary, @hMod
        
        ret
    GetFunAddr endp

    ;<<<<<<<<<<<<<<<<<<<<
    ;   ��ȡUnicode�ĳ���
    ;   ����ֵ�� eax�� ����
    ;>>>>>>>>>>>>>>>>>>>>
    BstrLen proc uses ECX EDI bstrSrc:DWORD
        or ecx, -1                  ;��ECX ȫF
        xor eax, eax              ;AX ��00
        mov edi, bstrSrc       ;EDI ָ���ַ����׵�ַ
        repnz scasw             ;ѭ������00���ҵ����˳�ѭ��
        not ecx                     ;ECX ȡ�� �õ����ȣ����Ǵ�ʱͳ����\0
        dec ecx                    ; ���� \0 �ĳ���
        
        mov eax, ecx            ; ����
        
        ret
    BstrLen endp
    
    ;<<<<<<<<<<<<<<<<<<<<
    ;   ��ȡAscii�ĳ���
    ;   ����ֵ�� eax�� ����
    ;>>>>>>>>>>>>>>>>>>>>
    StrLen proc uses ECX EDI pszSrc:DWORD
        or ecx, -1                  ;��ECX ȫF
        xor eax, eax              ;Al ��0
        mov edi, pszSrc       ;EDI ָ���ַ����׵�ַ
        repnz scasb             ;ѭ������0���ҵ����˳�ѭ��
        not ecx                     ;ECX ȡ�� �õ����ȣ����Ǵ�ʱͳ����\0
        dec ecx                    ; ���� \0 �ĳ���
        
        mov eax, ecx            ; ����
        
        ret
    StrLen endp
    
    
    GetTime proc uses EBX pszBuf: DWORD
        LOCAL @LocalTime: SYSTEMTIME
        
        lea eax, [@LocalTime]
        push eax
        call [ebx + g_pfnGetLocalTime]
        
        xor eax, eax
        mov ax, @LocalTime.wSecond
        push eax
        
        mov ax, @LocalTime.wMinute
        push eax
        
        mov ax, @LocalTime.wHour
        push eax
        
        mov ax, @LocalTime.wDay
        push eax
        
        mov ax, @LocalTime.wMonth
        push eax
        
        mov eax, offset g_szFmtStr
        add eax, ebx
        push eax
        
        mov eax, pszBuf
        push eax
        
        ;mov eax, [ebx + g_pfnWsprintf]
        ;add eax, ebx
        ;call  eax
        call [ebx + g_pfnWsprintf]
        
        or eax, 1
        ret
    GetTime endp

Remote_End:



;<<<<<<<<<<<<<<<<<<<<
;   Hook��ť
;>>>>>>>>>>>>>>>>>>>>
OnBtnHook proc
    LOCAL @dwDstPID: DWORD
    ;LOCAL @pRemoteAddr: DWORD
    
    ;�Ѿ�ע�����������
    .if g_bIsInject != FALSE
        invoke MessageBox, NULL, addr g_szRepInject, NULL, MB_OK
        ret
    .endif
    
    ;���ҽ���Ŀ�꣬��ý���PID
    invoke FindDstAndGetPID, addr g_szDstClassName, addr @dwDstPID
    .if eax == NULL
        invoke MessageBox, NULL, g_szGetPIDErr, NULL, MB_OK
        ret
    .endif

    ;��ʼ��ע�����
    invoke InitInjectCode, g_szLoadLibraryA, g_szGetProcAddr
    .if eax == NULL
        invoke MessageBox, NULL, g_szInitErr, NULL, MB_OK
        ret
    .endif
    
    ;ע�����
    invoke InjectCode, @dwDstPID, Remote_Begin, Remote_End - Remote_Begin
    .if eax == NULL
        invoke MessageBox, NULL, g_szInjectErr, NULL, MB_OK
        ret
    .endif

    ;����Ѿ�ע��
    mov g_bIsInject, TRUE
    ret

OnBtnHook endp

;<<<<<<<<<<<<<<<<<<<<
;   ���ҽ���Ŀ�꣬���Ŀ�����PID
;   pszDstName      Ŀ�������
;   hOutDstHandle ���صľ��
;   ����ֵ�� �ɹ�/ʧ��
;>>>>>>>>>>>>>>>>>>>>
FindDstAndGetPID proc  pszDstClassName: DWORD, hOutDstPID: HANDLE
    LOCAL @hDstWnd: HWND 
    ;���Ҵ��ڣ���ô��ھ��
    invoke FindWindow, pszDstClassName, NULL
    .if eax == NULL
        ret
    .endif
    mov @hDstWnd, eax
    
    ;ͨ�����ھ����ý���Pid
    invoke GetWindowThreadProcessId, @hDstWnd, hOutDstPID
    .if hOutDstPID == NULL
        and eax, 0
        ret
    .endif
    
    mov eax, TRUE
    ret
FindDstAndGetPID endp

;<<<<<<<<<<<<<<<<<<<<
;   ��ʼ��InjectCode����ú���ָ�룬���޸��ڴ汣������
;   pszLoadLibrary       LoadLibrary�ַ�����ַ
;   pszGetProcAddr     GetProcAddr�ַ�����ַ
;   ����ֵ�� �ɹ�/ʧ��
;>>>>>>>>>>>>>>>>>>>>
InitInjectCode proc pszLoadLibrary: DWORD, pszGetProcAddr: DWORD
    LOCAL @hMod: HMODULE 
    LOCAL @oldProtect:DWORD
    ;int 3
    
    ;�޸��ڴ汣������, �����޸�����
     invoke VirtualProtect, addr Remote_Begin, Remote_End - Remote_Begin, \
                                        PAGE_EXECUTE_READWRITE, addr @oldProtect
    .if eax == NULL
        invoke MessageBox, NULL, g_szProtectErr, NULL, MB_OK
        ret
    .endif

    ;����Kernel32
    invoke LoadLibraryA, addr g_szKernel32
    .if eax == NULL
        ret
    .endif
    mov @hMod, eax
    
    ;���LoadLibrary��ַ
    ;lea eax, [offset LoadLibraryW]
    ;lea edx, [offset GetProcAddress]
    invoke GetProcAddress, @hMod, addr g_szLoadLibraryA
    .if eax == NULL
        ret
    .endif
    mov g_pfnLoadLibrary, eax
    
    ;���GetProcAddr��ַ
    invoke GetProcAddress, @hMod, addr g_szGetProcAddr
    .if eax == NULL
        ret
    .endif
    mov g_pfnGetProcAddr, eax
    
    ;ж��Lib
    invoke FreeLibrary, @hMod
    
    ret
InitInjectCode endp

;<<<<<<<<<<<<<<<<<<<<
;   ע����뵽Ŀ�����, Я��LoadLibrary��GetProcAddr
;   dwPID             Ŀ�����ID
;   pSrcData         ��д�������
;   dwDataLen     ���ݳ���
;   dwOutRemoteAddr д��ɹ��ĵ�ַ
;   ����ֵ�� �ɹ�/ʧ��
;>>>>>>>>>>>>>>>>>>>>
InjectCode proc  dwPID: DWORD, pSrcData: DWORD, dwDataLen: DWORD
    LOCAL @hProc: HANDLE
    LOCAL @lpRemoteBuf: LPVOID
    LOCAL @dwWriten: DWORD
    
    ;�򿪽���
    invoke OpenProcess, PROCESS_ALL_ACCESS, FALSE, dwPID
    .if eax == NULL
        ret
    .endif
    mov @hProc, eax
    
    ;����Զ���ڴ�
    invoke VirtualAllocEx, @hProc, NULL, 1000h, MEM_COMMIT, PAGE_EXECUTE_READWRITE
    .if eax == NULL
        invoke GetLastError
        ret
    .endif
    mov @lpRemoteBuf, eax
    
    mov eax, [pSrcData]
    ;д��Զ���ڴ�
    invoke WriteProcessMemory, @hProc, @lpRemoteBuf, eax, dwDataLen, @dwWriten
    .if eax == NULL
        ret
    .endif
    ;int 3
    ;����Զ���߳�
    invoke CreateRemoteThread, @hProc, NULL, NULL, @lpRemoteBuf, NULL, NULL, NULL
    .if eax == NULL
        ret
    .endif
    
    ;�ͷ�Զ���ڴ�
    ret
InjectCode endp

;;<<<<<<<<<<<<<<<<<<<<
;;   ִ��Զ���̣߳���Զ���߳�
;;   ����ֵ�� �ɹ�/ʧ��
;;>>>>>>>>>>>>>>>>>>>>
;RunInjectCode proc
;    
;    ret
;RunInjectCode endp

end start