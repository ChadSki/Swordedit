
// **********************************************************************
// The Cheat - A universal game cheater for Mac OS X
// (C) 2003-2005 Chaz McGarvey (BrokenZipper)
// 
// This program is free software; you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation; either version 1, or (at your option)
// any later version.
// 
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
// 
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
// 


#ifndef _CheaterTypes_H
#define _CheaterTypes_H

#import <Cocoa/Cocoa.h>

#include <mach/vm_types.h>

#include <stdlib.h>
#include <string.h>


/* Compiler macros */
#if defined( __cplusplus )
#define CHEAT_EXPORT extern "C"
#define CHEAT_IMPORT extern "C"
#else
#define CHEAT_EXPORT extern
#define CHEAT_IMPORT extern
#endif

#if !defined( CHEAT_STATIC_INLINE )
#define CHEAT_STATIC_INLINE static __inline__
#endif

#if !defined( CHEAT_EXTERN_INLINE )
#define CHEAT_EXTERN_INLINE extern __inline__
#endif


#pragma mark -
#pragma mark Miscellaneous Types
/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

typedef vm_address_t TCAddress;


typedef unsigned char TCVariableType;
enum {
	TCInt64 = 0,
	TCInt32 = 1, // default
	TCInt16 = 2,
	TCInt8 = 3,
	TCString = 4,
	TCFloat = 5,
	TCDouble = 6
};

typedef unsigned char TCIntegerSign;
enum {
	TCSigned = 0, // default
	TCUnsigned = 1
};

typedef unsigned char TCSearchOperator;
enum {
	TCEqual = 0, // default
	TCNotEqual = 1,
	TCLessThan = 2,
	TCGreaterThan = 3,
	TCLessThanOrEqual = 4, // not used
	TCGreaterThanOrEqual = 5 // not used
};

typedef unsigned char TCSearchType;
enum {
	TCGivenValue = 0, // default
	TCLastValue = 1
};


#pragma mark -
#pragma mark TCArray
/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

typedef struct _TCArray
{
	void *_bytes;
	unsigned _count;
	unsigned _size;
	BOOL _ownsBytes;
} *TCArray;


#pragma mark -
#pragma mark Exported Array Functions
/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

CHEAT_EXPORT TCArray TCMakeArray( unsigned count, unsigned size );
CHEAT_EXPORT TCArray TCMakeArrayWithBytes( unsigned count, unsigned size, void *bytes );
CHEAT_EXPORT void TCReleaseArray( TCArray array );

CHEAT_EXPORT void TCArrayAppendArray( TCArray array, TCArray other );

CHEAT_EXPORT NSString *TCStringFromArray( TCArray array );


#pragma mark -
#pragma mark Imported Array Functions
/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

CHEAT_STATIC_INLINE void *TCArrayBytes( TCArray array )
{
	return array->_bytes;
}

CHEAT_STATIC_INLINE unsigned TCArrayElementCount( TCArray array )
{
	return array->_count;
}

CHEAT_STATIC_INLINE unsigned TCArrayElementSize( TCArray array )
{
	return array->_size;
}

CHEAT_STATIC_INLINE void const *TCArrayElementAtIndex( TCArray array, unsigned index )
{
	return array->_bytes + index * array->_size;
}

CHEAT_STATIC_INLINE void TCArraySetElementAtIndex( TCArray array, unsigned index, void const *element )
{
	memcpy( array->_bytes + index * array->_size, element, array->_size );
}

CHEAT_STATIC_INLINE void TCArrayResize( TCArray array, unsigned count )
{
	void *bytes = realloc( array->_bytes, count * array->_size );
	
	if ( bytes ) {
		array->_bytes = bytes;
		array->_count = count;
	}
}

CHEAT_STATIC_INLINE TCArray TCArrayCopyElements( TCArray array, unsigned count )
{
	return TCMakeArrayWithBytes( MIN(array->_count,count), array->_size, array->_bytes );
}

CHEAT_STATIC_INLINE TCArray TCArrayCopy( TCArray array )
{
	return TCArrayCopyElements( array, array->_count );
}

CHEAT_STATIC_INLINE TCArray TCArrayCopyContainer( TCArray array, unsigned count )
{
	TCArray copy = TCMakeArray( MIN(array->_count,count), array->_size );
	copy->_bytes = array->_bytes;
	copy->_ownsBytes = NO;
	return copy;
}

CHEAT_STATIC_INLINE void TCArrayFill( TCArray array, int filler )
{
	memset( array->_bytes, filler, array->_count * array->_size );
}



#endif /* _CheaterTypes_H */

