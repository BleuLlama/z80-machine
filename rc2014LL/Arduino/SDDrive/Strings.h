
/* Version info
 *  
 *  v001 : 2016-10-01  yorgle@gmail.com
 */

#define kStr_Version              "-N0=SSDD1,v001"
/* Version string is the following format:
 *  {header}={deviceID},{device's version number}
 *  SSDD1 = Serial SD Drive 1
 */

// Error responses
#define kStr_Error_NoCard         "-E0=No card"
#define kStr_Error_InitFailed     "-E1=SD Init failed"
#define kStr_Error_NoFatPartition "-E2=No FAT"
#define kStr_Error_NotImplemented "-E3=Nope"

#define kStr_Error_BadLine        "-E4=Bad Line"
#define kStr_Error_LEcho          "-E5="

#define kStr_Error_CmdFail        "-E6=Failed"

// Notification responses
#define kStr_CardOk               "-N1=Card OK"
#define kStr_CmdOK                "-N2=OK"

#define kStr_FAType               "-Nt=FAT" /* FAT32 */
#define kStr_Size                 "-Ns="
#define kStr_SizeUnits                     ",meg"

#define kStr_Begin                "-Nbf="  /* begin file content */
#define kStr_End                  "-Nef="  /* end file content */

