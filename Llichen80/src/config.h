/* Config header
 *
 *  2019-09-18 Scott Lawrence
 *
 *   common configuration stuff.
 */

#ifndef __CONFIG_H__
#define __CONFIG_H__



////////////////////////////////////////
// System stuff

#define kMem0000RomFile "LL/ROM/BASIC32.ROM"


////////////////////////////////////////
// Autoboot stuff

#define kAutoBootPhrase		"Memory top? 0"
#define kAutoBootCommand	"boot"

// This is the starting path on our filesystem
#define kHomePath ("LL/")

// this is the file autoloaded when "Memory Size? 0"
#define kBootFile ("BAS/BOOTC000.BAS")

///////////////////////////////////////

#endif
