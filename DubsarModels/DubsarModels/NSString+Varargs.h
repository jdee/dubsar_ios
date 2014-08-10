/*
 Dubsar Dictionary Project
 Copyright (C) 2010-14 Jimmy Dee

 This program is free software; you can redistribute it and/or
 modify it under the terms of the GNU General Public License
 as published by the Free Software Foundation; either version 2
 of the License, or (at your option) any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with this program; if not, write to the Free Software
 Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

@import Foundation;

/*
 * This category makes it possible to write your own varargs Obj-C methods. The problem is that
 * vsprintf and friends don't understand %@. So we convert on an arg-by-arg basis and build a
 * new string.
 */
@interface NSString(DubsarVarargs)

+ (NSString*)stringWithFormat:(NSString*)format args:(va_list)args;

@end
